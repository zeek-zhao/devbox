#!/usr/bin/env bash
# 错误身份：一次失败从最底层传到最顶层，它的身份（退出码 + 诊断消息）必须不变。
# 中间层只透传（return "$rc"）；任何一层换码或吞成 0，身份就断了。
set -euo pipefail

CODE_MISSING=7

emit_failure() {
  printf 'missing-config\n' >&2
  return "$CODE_MISSING"
}

layer_inner() {
  emit_failure
}

layer_middle() {
  local rc=0
  layer_inner || rc=$?
  return "$rc"
}

layer_entry() {
  local rc=0
  layer_middle || rc=$?
  return "$rc"
}

layer_swallow() {
  # 反面教材：把失败吞成 0，身份在这一层被销毁。
  layer_inner || return 0
}

observe() {
  # 在某一层观察经过的错误：码与诊断文本一起接住。
  local name="$1"
  shift
  local rc=0
  local diagnostics
  diagnostics="$("$@" 2>&1 >/dev/null)" || rc=$?
  printf 'layer=%s code=%d message=%s\n' "$name" "$rc" "$diagnostics"
}

main() {
  observe inner layer_inner
  observe middle layer_middle
  observe entry layer_entry
  observe swallowed layer_swallow
  printf 'transparent chain: identity preserved\n'
  printf 'swallowing: identity broken (code 7 -> 0)\n'
}

main "$@"
