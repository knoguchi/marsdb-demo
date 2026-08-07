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

## About the data

None of these datasets are vendored in this repo. Each demo's `load.sh`
fetches the load script directly from its original source at run time —
see that demo's own README for attribution.
