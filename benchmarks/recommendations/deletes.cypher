# Canonical delete queries, same `# name:` block format as queries.cypher.
# Run last, against a freshly-loaded copy (bench.sh reloads before this
# phase) -- destructive, order matters (a bulk delete before a point
# delete could make the point delete a no-op and silently measure
# nothing).

# name: delete_single_relationship
MATCH (u:User {name: 'Misty Williams'})-[r:RATED]->(m:Movie {title: 'Crimson Tide'}) DELETE r;

# name: detach_delete_single_node
MATCH (m:Movie {title: 'Kite'}) DETACH DELETE m;

# name: bulk_delete_by_predicate
MATCH (u:User)-[r:RATED]->(m:Movie) WHERE r.rating < 1.0 DELETE r;
