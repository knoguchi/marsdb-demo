# natural-language

Plain-English questions against the recommendations dataset, translated
to real Cypher by an LLM and actually run — via
[`marsdb-nl2cypher`](https://github.com/knoguchi/marsdb/tree/main/marsdb-nl2cypher),
MarsDB's schema-introspecting NL-to-Cypher crate, and a local
[Ollama](https://ollama.com) instance as the LLM backend.

## Run it

```
ollama serve &
ollama pull qwen3-coder:30b        # or any model you already have

../visualize/load.sh               # loads the dataset if you haven't already

./run.sh
OLLAMA_MODEL=llama3.2 ./run.sh     # use a different pulled model
```

## What it actually does

`translate_and_run()` (1) introspects the *real* schema of whatever
database you point it at — labels, relationship types, property keys
actually observed, not a hardcoded description — (2) builds a prompt
telling the model both what MarsDB's Cypher subset supports and,
explicitly, what to avoid (MarsDB's grammar is narrower than full Neo4j
Cypher — see the [Cypher Language Support
chapter](https://knoguchi.github.io/marsdb/cypher-support.html) — a
smaller target surface means fewer ways an LLM generates something
unparseable), (3) calls the model, (4) actually parses and runs whatever
comes back, with one bounded repair attempt (feeding the real parse
error back to the model) if the first try doesn't parse.

Two real runs (`qwen3-coder:30b`), not one cherry-picked — the model
isn't deterministic, so the generated Cypher (and occasionally the
result) can differ run to run:

| Question | Run 1 | Run 2 |
|---|---|---|
| How many movies are there? | `MATCH (m:Movie) RETURN count(m)` -> 9,125 | same |
| Who directed Inception? | `MATCH (a)-[:DIRECTED]->(m) WHERE m.title = 'Inception' RETURN a.name` -> Christopher Nolan | same |
| What movies is Robert De Niro in? Show 5. | `MATCH (a:Actor {name: 'Robert De Niro'})-[:ACTED_IN]->(m:Movie) RETURN m.title LIMIT 5` -> Raging Bull, We're No Angels, Awakenings, Goodfellas, Bang the Drum Slowly | same |
| Average rating for Horror movies? | `MATCH (m:Movie)-[:IN_GENRE]->(g:Genre) WHERE g.name = 'Horror' RETURN avg(m.imdbRating)` -> **6.09** | `MATCH (m:Movie)-[:IN_GENRE]->(g:Genre) WHERE g.name = 'Horror' MATCH (u:User)-[:RATED]->(m) RETURN avg(u.rating)` -> **null** |
| Top 5 users by ratings given? | `MATCH (u:User)-[:RATED]->(m:Movie) RETURN u.name, count(*) AS num_ratings ORDER BY num_ratings DESC LIMIT 5` -> Darlene Garcia (2,391), ... | same |

Run 2's Horror-rating query is a real, honest miss worth keeping here,
not hiding: `rating` lives on the `RATED` *relationship* (`r.rating`),
not the `User` node — the LLM wrote `u.rating` instead. That's not a
property MarsDB hallucinated (schema introspection is real, `User`
genuinely has no `rating` property), and the query is *syntactically and
semantically valid Cypher* — a missing property just reads as `null`,
so `avg()` over an all-null column correctly returns `null` rather than
erroring. Parses and runs cleanly ≠ the right query. Every run in this
table both parsed and ran on the first attempt (no repair pass needed
either time) — that bar and "gives you the right answer" are different
things, and this is the one case here where only the first was met.

Edit the question list directly in
[`marsdb-nl2cypher/examples/recommendations_nl.rs`](https://github.com/knoguchi/marsdb/blob/main/marsdb-nl2cypher/examples/recommendations_nl.rs)
(in your `marsdb` checkout) to try your own.
