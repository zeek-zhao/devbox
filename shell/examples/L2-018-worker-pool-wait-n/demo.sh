#!/usr/bin/env bash
# 并发 worker 池：wait -n 逐个收割完成的任务，统计成功与失败数。
set -euo pipefail

main() {
  local -a pids=()
  local task
  for task in 1 2 3 4 5 6; do
    (
      [[ "$task" -eq 4 ]] && exit 3
      exit 0
    ) &
    pids+=("$!")
  done

  local failed=0 ok=0
  local -a remaining=("${pids[@]}")
  while [[ "${#remaining[@]}" -gt 0 ]]; do
    wait -n || true
    local -a still=()
    local pid rc
    for pid in "${remaining[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        still+=("$pid")
      else
        rc=0
        wait "$pid" || rc=$?
        [[ "$rc" -eq 0 ]] && ok=$((ok + 1)) || failed=$((failed + 1))
      fi
    done
    remaining=("${still[@]}")
  done

  printf 'pool=workers6 ok=%d failed=%d\n' "$ok" "$failed"
}

main "$@"
