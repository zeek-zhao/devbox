#!/usr/bin/env bash
# 断点续跑：每个条目完成后写状态标记，重跑从未完成处继续。
set -euo pipefail

WORK="$1"
FAIL_AT="${FAIL_AT:-0}"
STATE="$WORK/state"
DONE_LOG="$WORK/done.log"
touch "$STATE" "$DONE_LOG"

items=(alpha beta gamma delta epsilon)
last="$(cat "$STATE" 2>/dev/null || echo 0)"

for i in "${!items[@]}"; do
  idx=$((i + 1))
  [[ "$idx" -le "$last" ]] && continue
  printf '%s\n' "${items[$i]}" >>"$DONE_LOG"
  echo "$idx" >"$STATE"
  if [[ "$FAIL_AT" -eq "$idx" ]]; then
    echo "interrupted at item $idx" >&2
    exit 1
  fi
done

[[ "$(wc -l <"$DONE_LOG")" -eq 5 ]]
