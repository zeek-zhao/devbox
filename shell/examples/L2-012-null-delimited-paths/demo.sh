#!/usr/bin/env bash
set -euo pipefail

mkdir "$1"
touch "$1/alpha space" "$1/line
break"
count="$(find "$1" -type f -print0 | xargs -0 -n1 printf 'X' | tr -cd X | wc -c | tr -d '[:space:]')"
[[ "$count" -eq 2 ]]
printf 'files: %s (NUL-delimited)\n' "$count"
