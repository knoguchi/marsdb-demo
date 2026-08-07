// Canonical queries from Neo4j's own Movie Graph guide
// (https://github.com/neo4j-graph-examples/movies), adapted to drop the
// $favorite parameter (inlined as a literal -- see demo README for why).
// Verified output for each is in this demo's README.md.

// Movies released after 2000
MATCH (m:Movie) WHERE m.released > 2000 RETURN m.title, m.released LIMIT 5;

// Count of movies released after 2005
MATCH (m:Movie) WHERE m.released > 2005 RETURN count(m);

// Who acted in movies released after 2010 (undirected pattern)
MATCH (p:Person)-[r:ACTED_IN]-(m:Movie) WHERE m.released > 2010 RETURN p.name, m.title LIMIT 5;

// People and birth years
MATCH (p:Person) RETURN p.name, p.born LIMIT 5;

// Reviews
MATCH (p:Person)-[r:REVIEWED]-(m:Movie) RETURN p.name, r.summary, r.rating, m.title LIMIT 5;

// Recommendation: co-actors' other movies (the guide's own headline example --
// original uses $favorite = "The Matrix", documented expected result includes
// "Cloud Atlas")
MATCH (movie:Movie {title:'The Matrix'})<-[:ACTED_IN]-(actor)-[:ACTED_IN]->(rec:Movie)
RETURN distinct rec.title as title LIMIT 20;

// Shortest path between two actors who never worked together directly
MATCH (a:Person {name:'Keanu Reeves'}), (b:Person {name:'Meg Ryan'})
MATCH p=shortestPath((a)-[*]-(b))
RETURN length(p) AS hops, [n IN nodes(p) | coalesce(n.name, n.title)] AS path;
