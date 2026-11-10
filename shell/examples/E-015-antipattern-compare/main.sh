#!/usr/bin/env bash
# 反模式对照：把 E 段踩过的坑集中成「坏写法 vs 好写法」的对照实验。
# 每一行都是一个真实可跑的对照，bad= 就是坏写法造成的现象。
set -euo pipefail

WORK=''

setup() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-e015.XXXXXX")"
  trap 'rm -rf "$WORK"' EXIT
  printf 'content\n' >"$WORK/my file.txt"
}

demo_swallow() {
  # 吞错：失败被 || true 洗成成功（E-008 的坑）。
  false || true
  local bad=$?
  local rc=0
  false || rc=$?
  printf 'antipattern=swallow-error bad=exit%d good=exit%d\n' "$bad" "$rc"
}

demo_unquoted() {
  # 未加引号的变量展开：带空格路径被分词（S-12 / E-004 的坑）。
  local file="$WORK/my file.txt"
  # shellcheck disable=SC2086  # 反面教材：故意不加引号演示分词
  set -- $file
  local bad=$#
  set -- "$file"
  local good=$#
  printf 'antipattern=unquoted-split bad=words=%d good=words=%d\n' "$bad" "$good"
}

demo_pipe() {
  # 管道吞错：中间命令失败被吞（S-12 / L1-021 的坑）。
  local bad
  bad="$(bash -c 'false | true; printf %s "$?"')"
  local good
  good="$(bash -c 'set -o pipefail; false | true; printf %s "$?"')"
  printf 'antipattern=pipe-middle-fail bad=exit%s good=exit%s\n' "$bad" "$good"
}

loud_failure() {
  # 反模式：诊断打到 stdout，污染管道数据。
  printf 'something failed\n'
}

quiet_failure() {
  # 正确：诊断走 stderr（E-002 的纪律）。
  printf 'something failed\n' >&2
}

demo_streams() {
  local bad
  bad="$(loud_failure 2>/dev/null | wc -l)"
  local good
  good="$(quiet_failure 2>/dev/null | wc -l)"
  printf 'antipattern=error-on-stdout bad=pipeline-lines=%d good=pipeline-lines=%d\n' \
    "$bad" "$good"
}

main() {
  setup
  demo_swallow
  demo_unquoted
  demo_pipe
  demo_streams
}

main "$@"
