# movies

Neo4j's [Movie Graph](https://github.com/neo4j-graph-examples/movies):
38 movies, 133 people (actors, directors, producers, reviewers), and
their relationships (`ACTED_IN`, `DIRECTED`, `PRODUCED`, `REVIEWED`,
`FOLLOWS`).

The dataset itself isn't vendored in this repo — no LICENSE file exists
on the source repo, but it's Neo4j's long-standing public demo dataset,
reused throughout their own docs and tutorials (`:play movies` in Neo4j
Browser). `load.sh` fetches the load script directly at run time.

## Run it

```
./load.sh movies.db
```

Loads via `marsdb movies.db "<script>"` — the whole 654-line script as
one call, `;`-separated statements, same as Neo4j's own `cypher-shell -f`.
The 2 `CREATE CONSTRAINT` lines are stripped first (not supported by
MarsDB — indexes/constraints are a different mechanism, see
[CYPHER_COVERAGE.md](https://github.com/knoguchi/marsdb/blob/main/CYPHER_COVERAGE.md)).
Everything else — `MERGE`, inline relationship properties, multi-label
nodes — loads as-is.

Then run any query from `queries.cypher` against it:

```
marsdb movies.db "MATCH (m:Movie) RETURN count(m)"
```

## Verified output

Each query below was checked against Neo4j's own documented behavior for
this dataset (the recommendation query's expected result is stated
directly in the [source repo's
README](https://github.com/neo4j-graph-examples/movies/blob/main/README.adoc));
the rest are queries lifted from their own tutorial guide
(`documentation/movies.adoc` in that repo).

**Movies released after 2000** (`LIMIT 5`):
```
m.title              | m.released
The Matrix Reloaded  | 2003
The Matrix Revolutions | 2003
RescueDawn            | 2006
Cloud Atlas            | 2012
The Da Vinci Code      | 2006
```

**Count of movies released after 2005:**
```
count(...)
8
```

**Recommendation** (co-actors' other movies, `$favorite = "The Matrix"`
inlined as a literal — this MarsDB CLI has no `--param` flag, so the demo
just hardcodes it; the query itself is identical to the original):
```
title
The Matrix Reloaded
The Matrix Revolutions
The Devil's Advocate
The Replacements
Johnny Mnemonic
Something's Gotta Give
Cloud Atlas          <- matches the source repo's own documented
V for Vendetta           expected-result annotation
```

**Shortest path** between two actors with no shared movie:
```
hops | path
6    | [Keanu Reeves, The Matrix, Hugo Weaving, Cloud Atlas, Tom Hanks, You've Got Mail, Meg Ryan]
```

## Known gap

The guide's `MERGE ... ON CREATE SET m.lastUpdatedAt = timestamp() ...`
example doesn't run — MarsDB has no `timestamp()` builtin. Everything
else in the guide that was tried works as shown above.
