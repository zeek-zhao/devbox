#!/usr/bin/env bash
# 错误创建：失败不是一句随手 echo，而是一条带约定字段的结构化报告：
#   流向   —— stderr（stdout 只留给业务输出）；
#   格式   —— <脚本名>: <发生地>: <发生了什么>；
#   退出码 —— 非零，且与失败类别一致。
# 统一出口以后，诊断信息的格式与流向不再散落各处。
set -euo pipefail

CODE_USAGE=2

err() {
  # 统一的错误创建出口：所有失败诊断都从这里过一遍。
  printf '%s: %s\n' "${0##*/}" "$*" >&2
}

validate_name() {
  if [ -z "$1" ]; then
    err 'validate-name: name is empty'
    return "$CODE_USAGE"
  fi
  return 0
}

report() {
  # 把一次失败的「诊断 + 码」按固定格式落到 stdout 汇总（诊断本体已在 stderr）。
  local diagnostics="$1" rc="$2"
  if [ -n "$diagnostics" ]; then
    printf '%s\n' "$diagnostics"
  fi
  printf 'rc=%d\n' "$rc"
}

observe() {
  # 运行一个步骤，分别接住它的 stderr 与退出码。
  local rc=0
  local diagnostics
  diagnostics="$("$@" 2>&1 >/dev/null)" || rc=$?
  report "$diagnostics" "$rc"
}

main() {
  observe validate_name ''
  observe validate_name devbox
}

main "$@"
