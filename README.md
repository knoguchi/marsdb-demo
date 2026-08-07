# marsdb-demo

Runnable demos of [MarsDB](https://github.com/knoguchi/marsdb) against
real-world graph datasets, with queries verified against known-correct
results from the dataset's original source.

## Install MarsDB

```
cargo install marsdb-cli
```

See [MarsDB's own README](https://github.com/knoguchi/marsdb#install) for
other install methods (Homebrew, building from source).

## Demos

| Demo | Dataset | Status |
|---|---|---|
| [movies](demos/movies) | Neo4j's Movie Graph (actors, movies, reviews) | Working |

### Planned, blocked on MarsDB feature gaps

- **northwind** ([source](https://github.com/neo4j-graph-examples/northwind)) —
  its load script uses `LOAD CSV`, which MarsDB doesn't implement. Would
  need pre-converting the CSVs into literal `CREATE`/`MERGE` statements
  instead of loading the script as-is.
- **network-management** ([source](https://github.com/neo4j-graph-examples/network-management)) —
  its load script uses `FOREACH`, which MarsDB's grammar doesn't have a
  rule for at all.

## Benchmarks

| Benchmark | Dataset | What it measures |
|---|---|---|
| [recommendations](benchmarks/recommendations) | Neo4j's recommendations graph (28,863 nodes, 166,261 relationships) | Load/query/update/delete, MarsDB vs Neo4j, same statements |

## Visualize

[`visualize`](visualize) renders a real network graph (Python,
`marsdb`+`networkx`+`matplotlib`) from a MarsDB query against the
recommendations dataset above — an actor's ensemble-cast co-star network,
not a toy example.

## Natural language

[`natural-language`](natural-language) — plain-English questions against
the recommendations dataset, translated to real Cypher by a local LLM
(via [`marsdb-nl2cypher`](https://github.com/knoguchi/marsdb/tree/main/marsdb-nl2cypher)
+ Ollama) and actually run. Includes an honest example of the LLM
getting a query wrong (right property, wrong graph element) that still
parses and runs cleanly — not just the successful runs.

## About the data

`demos/movies`' dataset isn't vendored — its `load.sh` fetches the load
script directly from its original source at run time (a plain Cypher
file, small enough to just curl on demand).

`benchmarks/recommendations`' dataset *is* vendored (gzipped, in `data/`)
— its only source is a Neo4j-proprietary `.dump` file with no plain
script anywhere, so getting a portable Cypher version out of it requires
running a real Neo4j instance once (see that benchmark's own README for
the exact extraction steps); committing the result means `bench.sh`
doesn't need Docker+Neo4j+APOC just to load MarsDB's side.
