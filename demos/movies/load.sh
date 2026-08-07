#!/usr/bin/env bash
# Fetches Neo4j's Movie Graph load script and runs it against a fresh
# MarsDB database file. Source: https://github.com/neo4j-graph-examples/movies
# (no LICENSE file on that repo; this is Neo4j's long-standing public demo
# dataset, reused widely in their own docs/tutorials -- see README.md).
set -euo pipefail

SCRIPT_URL="https://raw.githubusercontent.com/neo4j-graph-examples/movies/main/scripts/movies.cypher"
DB_FILE="${1:-movies.db}"

echo "Fetching $SCRIPT_URL ..."
script="$(curl -sL "$SCRIPT_URL")"

# CREATE CONSTRAINT isn't supported by MarsDB (see CYPHER_COVERAGE.md's
# "Not yet supported" list) -- strip the two constraint lines, everything
# else in this script is plain MERGE/CREATE/MATCH.
script="$(echo "$script" | grep -v '^CREATE CONSTRAINT')"

rm -f "$DB_FILE"
echo "Loading into $DB_FILE ..."
marsdb "$DB_FILE" "$script"

echo "Done. 38 Movie nodes, 133 Person nodes expected:"
marsdb "$DB_FILE" "MATCH (m:Movie) RETURN count(m) AS movies"
marsdb "$DB_FILE" "MATCH (p:Person) RETURN count(p) AS people"
