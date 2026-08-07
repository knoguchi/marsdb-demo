# visualize

A real network graph rendered from a MarsDB query, using the
recommendations dataset already vendored in
[`benchmarks/recommendations`](../benchmarks/recommendations).

## Run it

```
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

./load.sh                    # loads into ./recommendations.db (gitignored)
python3 actor_network.py --center "Robert De Niro" --movies 8
```

Opens `actor_network.png`: an ensemble-cast network for the given actor's
first N movies (by whatever order MarsDB returns them in — no `ORDER BY`
here, just "the first N MATCH finds") — nodes are actors, an edge means
two actors appeared in the same movie together, edge width is how many
movies they share, the center actor highlighted in red. Try other names
(`--center "Nicolas Cage"`) or a bigger/smaller ensemble (`--movies 20`).

## The `marsdb` Python API used here

```python
import marsdb
db = marsdb.Database.open("recommendations.db")
rows = db.execute("MATCH (n:Movie) RETURN n.title LIMIT 5")  # -> list[dict]
```

`execute()` takes the Cypher string only — the published `marsdb` package
doesn't expose `$param` binding yet (the Rust API it wraps does), so
`actor_network.py` inlines the `--center` value as an escaped string
literal instead of a bound parameter (see `cypher_string_literal()` in
that file). Fine for a value you typed on your own command line, not a
pattern to copy for untrusted input.

## Why `load.sh` chunks the data manually

The dataset is ~29MB of Cypher text — too big to hand `marsdb` as a
single command-line argument (`marsdb`'s CLI takes one `QUERY` argument,
no `-f file`/stdin-batch mode yet, and most OSes cap a single argv string
well under 29MB). `load.sh` splits it into whole-statement batches under
that cap first. See the script itself for the exact awk.
