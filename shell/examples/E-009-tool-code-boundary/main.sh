#!/usr/bin/env bash
# 外部命令边界翻译：每个外部工具自带一套退出码语义（grep 0=命中 1=未命中 2=真错；
# diff 0=相同 1=有差异 2=真错）。边界上把「工具语义」翻译成本脚本自己的
# 错误体系，工具的原始码不应泄漏到上层。
set -euo pipefail

WORK=''

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-e009.XXXXXX")"
  trap 'rm -rf "$WORK"' EXIT
  printf 'apple\n' >"$WORK/needle.txt"
  printf 'apple\nbanana\n' >"$WORK/hay.txt"
  cp "$WORK/hay.txt" "$WORK/hay-copy.txt"
  printf 'cherry\n' >"$WORK/other.txt"
}

grep_kind() {
  local rc=0
  grep -Fq "$2" "$1" 2>/dev/null || rc=$?
  case "$rc" in
    0) printf 'tool=grep raw=%d kind=match action=use-result\n' "$rc" ;;
    1) printf 'tool=grep raw=%d kind=no-match action=use-default\n' "$rc" ;;
    *) printf 'tool=grep raw=%d kind=tool-broken action=stop\n' "$rc" ;;
  esac
}

diff_kind() {
  local rc=0
  diff -q "$1" "$2" >/dev/null 2>&1 || rc=$?
  case "$rc" in
    0) printf 'tool=diff raw=%d kind=same action=skip-write\n' "$rc" ;;
    1) printf 'tool=diff raw=%d kind=differ action=write\n' "$rc" ;;
    *) printf 'tool=diff raw=%d kind=tool-broken action=stop\n' "$rc" ;;
  esac
}

main() {
  setup
  grep_kind "$WORK/hay.txt" apple
  grep_kind "$WORK/other.txt" apple
  grep_kind "$WORK/missing.txt" apple
  diff_kind "$WORK/hay.txt" "$WORK/hay-copy.txt"
  diff_kind "$WORK/hay.txt" "$WORK/other.txt"
}

main "$@"
