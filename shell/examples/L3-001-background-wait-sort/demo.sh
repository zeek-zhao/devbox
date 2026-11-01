#!/usr/bin/env bash
set -euo pipefail

pids=()
for result in gamma alpha beta; do
  (printf '%s\n' "$result" >"$WORK/$result.result") &
  pids+=("$!")
done

for pid in "${pids[@]}"; do
  wait "$pid"
done

for result_file in "$WORK"/*.result; do
  cat "$result_file"
done | sort
