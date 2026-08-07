
## 2026-08-07T06:33:38Z (marsdb @ f35afd3)

```
=== MarsDB build ===
=== MarsDB: load ===
schema loaded in 55.081083ms
data loaded in 64.925445125s
nodes: QueryResult { columns: ["c"], rows: [[Property(Int(28863))]] }
rels: QueryResult { columns: ["c"], rows: [[Property(Int(166261))]] }
=== MarsDB: query ===
matrix_review_counts: 26.793209ms (3 rows)
misty_average_rating: 1.702958ms (1 rows)
crimson_tide_collaborative_filtering: 69.0685ms (5 rows)
inception_genre_similarity: 68.483792ms (5 rows)
misty_all_ratings: 633µs (100 rows)
query phase total: .220893000s
=== MarsDB: update ===
point_update_single_property: 5.451208ms (0 rows)
bulk_update_by_predicate: 49.99525ms (0 rows)
add_new_relationship: 4.941ms (0 rows)
update phase total: .085759000s
=== MarsDB: delete ===
delete_single_relationship: 6.851584ms (0 rows)
detach_delete_single_node: 5.124625ms (0 rows)
bulk_delete_by_predicate: 456.864458ms (0 rows)
delete phase total: .501422000s
=== Neo4j: (re)start fresh ===
=== Neo4j: load ===
load phase total: 178.924114000s
count(n)
28863
count(r)
166261
=== Neo4j: query ===
query phase total: 1.267156000s
=== Neo4j: update ===
update phase total: 1.083562000s
=== Neo4j: delete ===
delete phase total: 1.121471000s
```
