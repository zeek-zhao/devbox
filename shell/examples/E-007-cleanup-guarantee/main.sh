#!/usr/bin/env bash
# 清理保证：临时资源要在每一条退出路径上被释放，且清理动作不得顶替业务退出码——
# 「收尾清理自己失败，把业务失败换成清理的失败」是常见的假绿/误报源。
set -euo pipefail

work_dir=''

cleanup_ok() {
  # 正确形态的清理：只做清理、只写日志，不 exit、不改码。
  if [ -n "$work_dir" ] && [ -d "$work_dir" ]; then
    rm -rf "$work_dir"
  fi
  printf 'cleanup: scratch dir removed\n' >&2
}

task() {
  mkdir -p "$1/scratch"
  printf 'task: started\n' >&2
  return 3
}

run_right() {
  # trap EXIT 挂清理：无论从哪条路径退出，清理都会跑；业务退出码原样冒出。
  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/devbox-e007-right.XXXXXX")"
  trap cleanup_ok EXIT
  task "$work_dir"
}

broken_final_cleanup() {
  # 反面教材的清理：它是收尾的最后一条命令，而它自己会失败。
  if [ -n "$work_dir" ] && [ -d "$work_dir" ]; then
    rm -rf "$work_dir"
  fi
  # 上一版残留的标记文件不存在：这条命令必然失败（退出码 1）。
  [ -f /devbox-e007-unreachable-marker ]
}

run_wrong() {
  # 错误形态：业务失败被接住却忘了上抛，收尾清理成了最后一条命令，
  # 它自己的失败（退出码 1）顶替了业务退出码。
  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/devbox-e007-wrong.XXXXXX")"
  local rc=0
  task "$work_dir" || rc=$?
  broken_final_cleanup
}

main() {
  local rc=0
  run_right || rc=$?
  printf 'right-mode: business exit preserved: %d\n' "$rc"
  local swallowed=0
  run_wrong || swallowed=$?
  printf 'wrong-mode: observed exit=%d (business 3 masked by cleanup)\n' "$swallowed"
}

main "$@"
