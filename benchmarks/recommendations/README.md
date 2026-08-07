# recommendations benchmark

Load/query/update/delete comparison between MarsDB and Neo4j on the same
real dataset: Neo4j's own [recommendations example
graph](https://github.com/neo4j-graph-examples/recommendations) (movies +
cast/crew from OMDb, users + ratings from MovieLens) — 28,863 nodes,
166,261 relationships.

Meant to be run repeatedly as MarsDB's internals change, not just once —
`bench.sh` appends a timestamped, git-sha-tagged block to `results.md`
each time rather than overwriting.

## Run it

```
./bench.sh                 # both engines
./bench.sh --marsdb-only   # skip Neo4j/Docker entirely
./bench.sh --neo4j-only
```

Requires a `marsdb` repo checkout as a sibling of `marsdb-demo` (i.e.
`../../../mars` relative to this file — override with `MARSDB_REPO=`),
Docker (for the Neo4j side), and `gunzip`.

## Layout

- `data/recommendations.cypher.gz` — the dataset itself: plain `CREATE`/
  `UNWIND`/`MATCH`/`CREATE` statements, no index/constraint declarations
  (those are separate per engine, see below), no `:begin`/`:commit`
  meta-commands. Extracted once from Neo4j's own dump via a real Neo4j
  5.26 instance + APOC (`apoc.export.cypher.all`) — see [How this was
  extracted](#how-this-was-extracted) below to redo it from scratch.
- `schema/marsdb.cypher` / `schema/neo4j.cypher` — matching index
  declarations per engine (5 unique + 8 plain, mirroring the source
  dataset's own schema). MarsDB has no `CREATE CONSTRAINT` concept, so
  its unique-constraint equivalents are `CREATE INDEX ... UNIQUE`.
- `queries.cypher` / `updates.cypher` / `deletes.cypher` — the actual
  benchmark statements, `# name: <label>` per block. `queries.cypher`'s
  5 are lifted verbatim (params inlined) from Neo4j's own tutorial guide
  for this dataset, not invented. `updates.cypher`/`deletes.cypher`
  cover a representative point-write, bulk-write, and relationship-write
  each.
- `bench.sh` — the runner.
- `results.md` — append-only log of real runs.

## Why phase totals, not per-query numbers, compare engines

MarsDB's numbers come from one in-process `Database` handle running every
statement in a phase — the per-query breakdown `bench.sh` prints for it
is real. Neo4j only has `cypher-shell`; spawning a fresh `docker exec`
per statement would make *every* query read ~0.9s regardless of what it
actually does (pure process/connection cold-start cost), so each phase
instead goes through *one* `cypher-shell` session. That means Neo4j only
gets a phase total, not a per-statement breakdown — `bench.sh` reports a
phase total for both engines so that number, at least, is apples-to-apples.

## How this was extracted

The source dataset ships only as a Neo4j-proprietary `.dump` file (no
plain Cypher/CSV script anywhere in the source repo) — version-locked to
specific Neo4j storage-engine releases, openable only by Neo4j itself.

```sh
# 1. Download the dump matching a real Neo4j version you can run.
curl -sL -o recommendations.dump \
  https://raw.githubusercontent.com/neo4j-graph-examples/recommendations/main/data/recommendations-5.26.dump

# 2. Load it into a real Neo4j 5.26 instance (neo4j-admin needs the file
#    named exactly <database>.dump under --from-path; Community Edition
#    only supports the default `neo4j` database, not an arbitrary name).
mkdir -p data backups && cp recommendations.dump backups/neo4j.dump
docker run --rm -v "$PWD/data:/data" -v "$PWD/backups:/backups" neo4j:5.26 \
  neo4j-admin database load --from-path=/backups neo4j --overwrite-destination=true

# 3. Start it for real, with APOC (needed for the export step).
docker run -d --name neo4j-extract \
  -v "$PWD/data:/data" -v "$PWD/import:/var/lib/neo4j/import" \
  -e NEO4J_AUTH=neo4j/<password> -e NEO4J_PLUGINS='["apoc"]' \
  -e NEO4J_apoc_export_file_enabled=true \
  neo4j:5.26

# 4. Export back out as plain Cypher (not the default cypher-shell
#    format -- that emits :begin/:commit meta-commands and can batch
#    rows behind UNWIND $rows-style parameters, neither of which is
#    portable outside cypher-shell itself).
docker exec neo4j-extract cypher-shell -u neo4j -p <password> \
  "CALL apoc.export.cypher.all('recommendations.cypher', {format: 'plain'})"
```

The exported file still has the schema statements at the top (this repo's
`schema/neo4j.cypher` is those, lightly renamed) and uses `start`/`end` as
relationship-endpoint variable names — real Cypher allows this, and so
does MarsDB (`END` was a reserved word blocking it as a bound-variable
name until [marsdb#140](https://github.com/knoguchi/marsdb/pull/140)).
