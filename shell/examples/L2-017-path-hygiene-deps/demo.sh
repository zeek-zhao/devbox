#!/usr/bin/env bash
# 依赖前置检查：开始工作前确认全部依赖命令可用，缺了立即报缺项退出。
set -euo pipefail

REQUIRED=(bash awk sed grep)

main() {
  local missing=()
  local cmd
  for cmd in "${REQUIRED[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    printf 'missing: %s\n' "${missing[*]}" >&2
    exit 1
  fi
  printf 'deps=ok\n'
}

main "$@"
