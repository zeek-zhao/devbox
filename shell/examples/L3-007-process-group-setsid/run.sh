#!/usr/bin/env bash
# 进程组与会话：setsid 启动的整组进程可用 kill -- -PGID 一次终止。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-007-process-group-setsid.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

setsid bash -c 'sleep 60 & sleep 60 & wait' &
leader=$!

pgid=""
for _ in $(seq 1 50); do
  pgid="$(ps -o pgid= -p "$leader" 2>/dev/null | tr -d ' ')"
  [[ -n "$pgid" ]] && break
  sleep 0.1
done
[[ -n "$pgid" ]]
[[ "$pgid" != "$$" ]]

members=0
for _ in $(seq 1 50); do
  members="$(ps -eo pid=,pgid= 2>/dev/null | awk -v g="$pgid" '$2==g' | wc -l)"
  [[ "$members" -ge 3 ]] && break
  sleep 0.1
done
[[ "$members" -ge 3 ]]

kill -- -"$pgid"

remaining=0
for _ in $(seq 1 50); do
  remaining="$(ps -eo pid=,pgid= 2>/dev/null | awk -v g="$pgid" '$2==g' | wc -l)"
  [[ "$remaining" -eq 0 ]] && break
  sleep 0.1
done
[[ "$remaining" -eq 0 ]]
printf 'pgroup=killed members=%d remaining=%d\n' "$members" "$remaining"
