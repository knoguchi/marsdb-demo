# Canonical read queries, lifted from Neo4j's own tutorial guide for this
# dataset (documentation/recommendations.adoc in
# https://github.com/neo4j-graph-examples/recommendations). Each is
# `# name: <label>` on its own line, then the query on the next line(s), one
# statement per block, blocks separated by a blank line. bench.sh parses
# this format directly -- keep it exactly like this if you add more.

# name: matrix_review_counts
MATCH (m:Movie)<-[:RATED]-(u:User) WHERE m.title CONTAINS 'Matrix' WITH m, count(*) AS reviews RETURN m.title AS movie, reviews ORDER BY reviews DESC LIMIT 5;

# name: misty_average_rating
MATCH (u:User {name: 'Misty Williams'}) MATCH (u)-[r:RATED]->(m:Movie) RETURN avg(r.rating) AS average;

# name: crimson_tide_collaborative_filtering
MATCH (m:Movie {title: 'Crimson Tide'})<-[:RATED]-(u:User)-[:RATED]->(rec:Movie) WITH rec, COUNT(*) AS usersWhoAlsoWatched ORDER BY usersWhoAlsoWatched DESC LIMIT 5 RETURN rec.title AS recommendation, usersWhoAlsoWatched;

# name: inception_genre_similarity
MATCH (m:Movie)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie) WHERE m.title = 'Inception' WITH rec, collect(g.name) AS genres, count(*) AS commonGenres RETURN rec.title, genres, commonGenres ORDER BY commonGenres DESC LIMIT 5;

# name: misty_all_ratings
MATCH (u:User {name: 'Misty Williams'}) MATCH (u)-[r:RATED]->(m:Movie) RETURN m.title, r.rating LIMIT 100;
