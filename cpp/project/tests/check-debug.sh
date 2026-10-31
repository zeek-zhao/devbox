#!/usr/bin/env bash
# L2-007-gdb-debugging: Debug symbols expose both the query argument and caller.
set -euo pipefail

BINARY="$1"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/devbox-cpp-debug-XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
printf 'alpha beta\n' >"$TEMP/input"
gdb --batch \
  -ex 'set pagination off' \
  -ex 'break devbox::InvertedIndex::query' \
  -ex run -ex bt -ex 'print word' \
  --args "$BINARY" "$TEMP/input" alpha >"$TEMP/backtrace" 2>&1
grep -q 'InvertedIndex::query' "$TEMP/backtrace"
grep -q 'main ' "$TEMP/backtrace"
grep -q 'alpha' "$TEMP/backtrace"
cat "$TEMP/backtrace" >&2
