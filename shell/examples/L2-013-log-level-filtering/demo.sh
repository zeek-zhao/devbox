#!/usr/bin/env bash
# 按级别过滤日志：低于阈值的行不产生输出。
set -euo pipefail

LEVELS=(debug info warn error)
level_rank() {
  local i
  for i in "${!LEVELS[@]}"; do
    [[ "$1" == "${LEVELS[$i]}" ]] && {
      echo "$i"
      return
    }
  done
  echo -1
}

main() {
  local threshold
  threshold="$(level_rank "${LOG_LEVEL:-info}")"
  [[ "$threshold" -ge 0 ]]

  local lvl
  for lvl in "${LEVELS[@]}"; do
    if [[ "$(level_rank "$lvl")" -ge "$threshold" ]]; then
      printf '%s: %s line\n' "$lvl" "$lvl"
    fi
  done
}

main "$@"
