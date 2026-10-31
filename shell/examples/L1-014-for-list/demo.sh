#!/usr/bin/env bash
set -euo pipefail

for item in "one two" three; do
  printf 'item: <%s>\n' "$item"
done
