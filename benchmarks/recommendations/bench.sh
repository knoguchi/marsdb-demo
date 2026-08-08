#!/usr/bin/env bash
# Reusable load/query/update/delete benchmark: MarsDB vs Neo4j, same
# dataset, same statements, same order (load -> query -> update -> delete,
# sequential on one instance per engine -- update/delete phases mutate on
# purpose, matching how a real deployment behaves, not reset between
# phases). Run this again and again as MarsDB's internals change; results
# get appended to results.md with a timestamp and the marsdb crate's git
# sha so you can track a series of runs, not just one.
#
# Phase totals (not per-query numbers) are the comparable figure between
# engines: MarsDB's `run_named_queries` runs in-process, one open
# Database handle, so per-query numbers there are real; Neo4j only has
# `cypher-shell`, and spawning one `docker exec` per statement makes every
# number ~0.9s of process/connection cold-start regardless of the query
# -- so each phase is fed to *one* cypher-shell session instead, timed as
# a whole. MarsDB's own per-query breakdown is still printed too (useful
# on its own), just not directly comparable to Neo4j's phase total.
#
# Requires: a `marsdb`-repo checkout next to this one (for the release
# binaries and example loaders), Docker (for the Neo4j side), gunzip.
#
# Usage: ./bench.sh [--marsdb-only] [--neo4j-only]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARSDB_REPO="${MARSDB_REPO:-$HERE/../../../mars}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-benchpassword123}"
CONTAINER_NAME="marsdb-bench-neo4j"

RUN_MARSDB=true
RUN_NEO4J=true
for arg in "$@"; do
  case "$arg" in
    --marsdb-only) RUN_NEO4J=false ;;
    --neo4j-only) RUN_MARSDB=false ;;
  esac
done

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

gunzip -k -c "$HERE/data/recommendations.cypher.gz" > "$WORKDIR/data.cypher"

RESULTS="$WORKDIR/results.txt"
: > "$RESULTS"

if $RUN_MARSDB; then
  echo "=== MarsDB build ===" | tee -a "$RESULTS"
  (cd "$MARSDB_REPO" && cargo build --release --example run_named_queries -p marsdb -p marsdb-cli)
  # The loader is this repo's own tooling (benchmarks/recommendations/loader),
  # built against the sibling marsdb checkout via its path dependency.
  (cd "$HERE/loader" && cargo build --release)
  MARSDB_SHA="$(cd "$MARSDB_REPO" && git rev-parse --short HEAD)"

  DB="$WORKDIR/marsdb.db"
  run_phase_marsdb() {
    local file="$1" label="$2"
    echo "=== MarsDB: $label ===" | tee -a "$RESULTS"
    t0=$(date +%s.%N)
    "$MARSDB_REPO/target/release/examples/run_named_queries" "$DB" "$file" | tee -a "$RESULTS"
    t1=$(date +%s.%N)
    echo "$label phase total: $(echo "$t1 - $t0" | bc)s" | tee -a "$RESULTS"
  }

  echo "=== MarsDB: load ===" | tee -a "$RESULTS"
  "$HERE/loader/target/release/load_recommendations" "$DB" "$HERE/schema/marsdb.cypher" "$WORKDIR/data.cypher" | tee -a "$RESULTS"

  run_phase_marsdb "$HERE/queries.cypher" query
  run_phase_marsdb "$HERE/updates.cypher" update
  run_phase_marsdb "$HERE/deletes.cypher" delete
fi

if $RUN_NEO4J; then
  echo "=== Neo4j: (re)start fresh ===" | tee -a "$RESULTS"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker run -d --name "$CONTAINER_NAME" \
    -e NEO4J_AUTH="neo4j/$NEO4J_PASSWORD" \
    neo4j:5.26 >/dev/null
  for i in $(seq 1 60); do
    docker exec "$CONTAINER_NAME" cypher-shell -u neo4j -p "$NEO4J_PASSWORD" "RETURN 1" >/dev/null 2>&1 && break
    sleep 1
  done

  cypher() { docker exec -i "$CONTAINER_NAME" cypher-shell -u neo4j -p "$NEO4J_PASSWORD" "$@"; }
  cypher_stdin() { docker exec -i "$CONTAINER_NAME" cypher-shell -u neo4j -p "$NEO4J_PASSWORD"; }

  echo "=== Neo4j: load ===" | tee -a "$RESULTS"
  cat "$HERE/schema/neo4j.cypher" "$WORKDIR/data.cypher" > "$WORKDIR/neo4j-load.cypher"
  t0=$(date +%s.%N)
  cypher_stdin < "$WORKDIR/neo4j-load.cypher" > "$WORKDIR/neo4j-load.log" 2>&1
  t1=$(date +%s.%N)
  echo "load phase total: $(echo "$t1 - $t0" | bc)s" | tee -a "$RESULTS"
  cypher "MATCH (n) RETURN count(n)" | tee -a "$RESULTS"
  cypher "MATCH ()-[r]->() RETURN count(r)" | tee -a "$RESULTS"

  # One cypher-shell session per phase, not one per statement -- see the
  # file-level comment above for why (process/connection cold-start cost
  # would otherwise dominate every number). `# name:`/comment/blank lines
  # stripped first since cypher-shell only wants bare Cypher.
  run_phase_neo4j() {
    local file="$1" label="$2"
    grep -v '^#' "$file" | grep -v '^[[:space:]]*$' > "$WORKDIR/${label}.cypher"
    echo "=== Neo4j: $label ===" | tee -a "$RESULTS"
    t0=$(date +%s.%N)
    cypher_stdin < "$WORKDIR/${label}.cypher" > "$WORKDIR/${label}.log" 2>&1
    t1=$(date +%s.%N)
    echo "$label phase total: $(echo "$t1 - $t0" | bc)s" | tee -a "$RESULTS"
  }

  run_phase_neo4j "$HERE/queries.cypher" query
  run_phase_neo4j "$HERE/updates.cypher" update
  run_phase_neo4j "$HERE/deletes.cypher" delete

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1
fi

{
  echo
  echo "## $(date -u +%Y-%m-%dT%H:%M:%SZ)${MARSDB_SHA:+ (marsdb @ $MARSDB_SHA)}"
  echo
  echo '```'
  cat "$RESULTS"
  echo '```'
} >> "$HERE/results.md"

echo
echo "Appended to $HERE/results.md"
