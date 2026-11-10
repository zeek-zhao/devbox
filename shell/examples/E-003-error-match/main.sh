#!/usr/bin/env bash
# 错误匹配：同一个非零退出码背后可能是不同性质的问题——探测未命中是预期分支，
# 探测本身坏了才是真失败。出错后先按错误身份匹配分类，再决定动作。
set -euo pipefail

RC_NO_MATCH=1
RC_PROBE_BROKEN=2

probe() {
  # 模拟一个外部探测命令：传入模式决定它返回什么。
  case "$1" in
    miss) return "$RC_NO_MATCH" ;;
    broken) return "$RC_PROBE_BROKEN" ;;
    hit) return 0 ;;
  esac
}

handle() {
  local rc=0
  probe "$1" || rc=$?
  case "$rc" in
    0) printf 'rc=%d classified=hit action=use-result\n' "$rc" ;;
    "$RC_NO_MATCH") printf 'rc=%d classified=no-match action=use-default\n' "$rc" ;;
    "$RC_PROBE_BROKEN") printf 'rc=%d classified=probe-broken action=stop\n' "$rc" ;;
    *) printf 'rc=%d classified=unknown action=stop\n' "$rc" ;;
  esac
}

handle hit
handle miss
handle broken
