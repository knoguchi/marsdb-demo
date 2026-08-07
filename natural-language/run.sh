#!/usr/bin/env bash
# Runs marsdb-nl2cypher's recommendations_nl example against the
# recommendations dataset -- plain-English questions in, real Cypher +
# real results out, no repair pass needed on any of the built-in
# questions (see mars#146 for the verified run this was checked against).
#
# Requires: a `marsdb` repo checkout as a sibling of `marsdb-demo` (same
# convention as ../benchmarks/recommendations/bench.sh -- override with
# MARSDB_REPO=), Ollama running locally with a model pulled
# (`ollama pull qwen3-coder:30b`, or set OLLAMA_MODEL to one you already
# have).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARSDB_REPO="${MARSDB_REPO:-$HERE/../../../mars}"
DB="${1:-$HERE/../visualize/recommendations.db}"

if [ ! -f "$DB" ]; then
  echo "No database at $DB -- run ../visualize/load.sh first (or pass a path)." >&2
  exit 1
fi

if ! curl -sf http://localhost:11434/api/tags >/dev/null; then
  echo "Ollama doesn't seem to be running at localhost:11434 -- start it with \`ollama serve\`." >&2
  exit 1
fi

cd "$MARSDB_REPO"
cargo run --release -p marsdb-nl2cypher --example recommendations_nl -- "$DB"
