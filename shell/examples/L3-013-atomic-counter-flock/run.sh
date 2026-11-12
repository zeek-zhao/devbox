#!/usr/bin/env bash
# flock 临界区：两个并发进程各加 20 次，读-改-写放进锁内才不丢计数。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-013-atomic-counter-flock.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo 0 >"$WORK/counter"
touch "$WORK/lock"

bump() {
  local n=0
  while ((n < 20)); do
    (
      flock 9
      c="$(cat "$WORK/counter")"
      echo $((c + 1)) >"$WORK/counter"
    ) 9>"$WORK/lock"
    n=$((n + 1))
  done
}

bump &
bump
wait

total="$(cat "$WORK/counter")"
[[ "$total" -eq 40 ]]
printf 'flock=atomic total=%d\n' "$total"
