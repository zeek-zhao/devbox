#!/usr/bin/env bash
set -euo pipefail

count=0
limit=2

while ((count < limit)); do
  printf 'iteration: %s\n' "$count"
  count=$((count + 1))
done

printf 'final count: %s\n' "$count"
