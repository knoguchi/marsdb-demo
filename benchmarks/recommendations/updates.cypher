# Canonical write queries, same `# name:` block format as queries.cypher.
# Run against a freshly-loaded copy of the dataset each time (bench.sh
# reloads before this phase) -- these mutate the graph, re-running them
# against an already-mutated copy would measure something different each
# time.

# name: point_update_single_property
MATCH (m:Movie {title: 'Inception'}) SET m.tagline = 'Your mind is the scene of the crime.';

# name: bulk_update_by_predicate
MATCH (m:Movie) WHERE m.year > 2010 SET m.recent = true;

# name: add_new_relationship
MATCH (u:User {name: 'Misty Williams'}), (m:Movie {title: 'Fight Club'}) MERGE (u)-[r:RATED]->(m) SET r.rating = 5.0, r.timestamp = 1;
