#!/usr/bin/env bash
# 记录后重抛：失败要被记录（日志、上报、计数），但记录不能替代失败本身——
# 记完必须带着原码继续上抛。吞掉再记录，语义就变成「假装处理过」。
set -euo pipefail

CODE_QUOTA=4

step() {
  printf 'step: quota exceeded\n' >&2
  return "$CODE_QUOTA"
}

observe_only() {
  # 反面教材：记录了失败却把它吞掉，调用方看到成功。
  local rc=0
  step || rc=$?
  REPORT="step failed rc=$rc"
  return 0
}

observe_and_reraise() {
  # 正确形态：先记录，再原码上抛。
  local rc=0
  step || rc=$?
  REPORT="step failed rc=$rc"
  return "$rc"
}

main() {
  REPORT=''
  observe_only
  printf 'mode=swallow report=%s exit=0\n' "$REPORT"
  REPORT=''
  local rc=0
  observe_and_reraise || rc=$?
  printf 'mode=reraise report=%s exit=%d\n' "$REPORT" "$rc"
}

main "$@"
