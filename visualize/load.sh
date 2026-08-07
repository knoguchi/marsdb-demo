#!/usr/bin/env bash
# Loads the recommendations dataset into a persistent local db file for
# the visualization scripts to query -- reuses the same data/schema
# benchmarks/recommendations already has, doesn't duplicate it.
#
# The data file is ~29MB uncompressed -- too big to hand `marsdb` as a
# single command-line argument (most OSes cap a single argv string well
# under that, ARG_MAX is typically ~1MB), and `marsdb`'s CLI has no
# `-f file`/stdin-batch mode. Splits into whole-statement batches under
# that cap instead, loading each with its own `marsdb` call against the
# same persistent db file.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_DIR="$HERE/../benchmarks/recommendations"
DB="${1:-$HERE/recommendations.db}"
MAXBYTES=800000

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

gunzip -k -c "$BENCH_DIR/data/recommendations.cypher.gz" > "$WORKDIR/data.cypher"

# Groups the input into batches of *whole* statements (one or more lines
# ending in `;`), each capped at MAXBYTES -- never splits a statement
# across batches, a half statement is a syntax error.
awk -v MAXBYTES="$MAXBYTES" -v OUTDIR="$WORKDIR" '
  { stmt = stmt $0 "\n" }
  /;[ \t]*$/ {
    stmtbytes = length(stmt)
    if (batchbytes > 0 && batchbytes + stmtbytes > MAXBYTES) {
      n++
      outfile = sprintf("%s/batch-%05d.cypher", OUTDIR, n)
      printf "%s", batch > outfile
      close(outfile)
      batch = ""; batchbytes = 0
    }
    batch = batch stmt
    batchbytes += stmtbytes
    stmt = ""
  }
  END {
    if (batchbytes > 0) {
      n++
      outfile = sprintf("%s/batch-%05d.cypher", OUTDIR, n)
      printf "%s", batch > outfile
      close(outfile)
    }
  }
' "$WORKDIR/data.cypher"

rm -f "$DB"
marsdb "$DB" "$(cat "$BENCH_DIR/schema/marsdb.cypher")"

for f in "$WORKDIR"/batch-*.cypher; do
  marsdb "$DB" "$(cat "$f")" > /dev/null
done

echo "Loaded into $DB"
marsdb "$DB" "MATCH (n) RETURN count(n) AS nodes"
marsdb "$DB" "MATCH ()-[r]->() RETURN count(r) AS rels"
