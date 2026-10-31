#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-007-cli-parser"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Cli.java
java -cp "$OUT" Cli --limit 2
java -cp "$OUT" Cli --help > "$OUT/help.txt"
grep -Fxq 'usage: cli --limit <0..3>' "$OUT/help.txt"
echo "help=accepted"

check_invalid() {
  local label="$1"
  shift
  if java -cp "$OUT" Cli "$@" > "$OUT/$label.out" 2> "$OUT/$label.err"; then
    echo "$label unexpectedly passed" >&2
    exit 1
  fi
  test ! -s "$OUT/$label.out"
  grep -Fxq 'error: usage: cli --limit <0..3>' "$OUT/$label.err"
  echo "$label=rejected"
}

check_invalid unknown --other
check_invalid missing --limit
check_invalid nonnumeric --limit many
check_invalid negative --limit -1
