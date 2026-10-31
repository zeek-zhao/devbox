#!/usr/bin/env bash
set -euo pipefail

awk 'BEGIN { for (i = 1; i <= 5000; i++) printf "record-%04d payload\n", i }' > "$WORK/large.txt"
awk 'NR == 1 { first = $1 } { last = $1 } END {
  printf "lines: %d\nfirst: %s\nlast: %s\n", NR, first, last
}' "$WORK/large.txt"
