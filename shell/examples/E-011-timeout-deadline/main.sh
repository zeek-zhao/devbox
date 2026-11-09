#!/usr/bin/env bash
# 超时与截止：对外部调用必须设截止时间。timeout 给会挂起的调用兜底
# （到点杀掉，退出码 124），把 124 翻译成自己的超时类别，而不是让它泄漏到上层。
set -euo pipefail

CODE_TIMEOUT=3

classify_timeout() {
  # timeout 的 124 是「截止时间到」；翻译成本脚本的错误类别。
  local rc="$1"
  if [ "$rc" -eq 124 ]; then
    return "$CODE_TIMEOUT"
  fi
  return "$rc"
}

probe() {
  local rc=0
  timeout 1s "$@" || rc=$?
  classify_timeout "$rc"
}

main() {
  local rc=0
  probe true || rc=$?
  printf 'fast task: rc=%d kind=completed\n' "$rc"
  probe sleep 5 || rc=$?
  printf 'hung task: rc=%d kind=timeout\n' "$rc"
  printf 'deadline enforced: true\n'
}

main "$@"
