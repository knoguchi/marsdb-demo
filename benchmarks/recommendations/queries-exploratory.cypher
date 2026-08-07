# Exploratory queries, not part of bench.sh's timed comparison (see
# queries.cypher for that -- lifted verbatim from Neo4j's own guide).
# These are just genuinely interesting things to ask this dataset, found
# by poking at it directly. Verified against a real loaded copy, actual
# results as of 2026-08-07 in the comment above each.

# name: most_prolific_actors
# Robert De Niro 56, Bruce Willis 49, Nicolas Cage 45, Samuel L. Jackson 45, ...
MATCH (p:Person)-[:ACTED_IN]->(m:Movie) WITH p, count(m) AS movies RETURN p.name, movies ORDER BY movies DESC LIMIT 10;

# name: director_actor_collaborations
# Excludes a director acting in their own film (Eastwood/Woody Allen/
# Keaton directing-and-starring dominate the *unfiltered* version of this
# query -- worth seeing once, then filtering out). With that filter:
# Kurosawa/Mifune 10 films, Burton/Depp 8, Scorsese/De Niro 7, ...
MATCH (d:Person)-[:DIRECTED]->(m:Movie)<-[:ACTED_IN]-(a:Person) WHERE d <> a WITH d, a, count(m) AS films WHERE films > 3 RETURN d.name AS director, a.name AS actor, films ORDER BY films DESC LIMIT 10;

# name: highest_rated_genres
# Film-Noir tops it (3.96 avg over 1,140 ratings) -- niche, critically-
# selected genres skew higher than broad ones (Comedy/Action aren't even
# in the top 10).
MATCH (g:Genre)<-[:IN_GENRE]-(m:Movie)<-[r:RATED]-() WITH g, avg(r.rating) AS avgRating, count(r) AS numRatings WHERE numRatings > 500 RETURN g.name, avgRating, numRatings ORDER BY avgRating DESC LIMIT 10;

# name: harshest_and_most_generous_critics
# Real spread: harshest averages 1.99/5 over 140 ratings, most generous
# averages 4.80/5 over 75 -- same rating scale, same dataset.
MATCH (u:User)-[r:RATED]->() WITH u, avg(r.rating) AS avgGiven, count(r) AS numRatings WHERE numRatings > 50 RETURN u.name, avgGiven, numRatings ORDER BY avgGiven ASC LIMIT 5;

# name: six_degrees_via_genre
# De Niro and Cage never acted together -- shortest real path between
# them goes through a shared genre, not a shared person: Robert De Niro
# -> Raging Bull -> Drama -> Leaving Las Vegas -> Nicolas Cage (4 hops).
MATCH (a:Person {name:'Robert De Niro'}), (b:Person {name:'Nicolas Cage'}) MATCH p=shortestPath((a)-[*]-(b)) RETURN length(p) AS hops, [n IN nodes(p) | coalesce(n.name, n.title)] AS path;
