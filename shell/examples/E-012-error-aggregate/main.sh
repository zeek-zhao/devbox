#!/usr/bin/env bash
# 聚合失败：批量任务不因第一个失败中断——逐个执行、逐个记录，
# 最后汇总失败清单，并以非零码整体上抛「本批有失败」。
set -euo pipefail

failures=''

task() {
  # 模拟批处理任务：beta、gamma 会失败。
  case "$1" in
    beta) return 3 ;;
    gamma) return 2 ;;
    *) return 0 ;;
  esac
}

run_batch() {
  local item rc
  local passed=0
  local failed=0
  for item in alpha beta gamma delta; do
    rc=0
    task "$item" || rc=$?
    if [ "$rc" -eq 0 ]; then
      printf 'item=%s status=ok\n' "$item"
      passed=$((passed + 1))
    else
      printf 'item=%s status=failed rc=%d\n' "$item" "$rc"
      failures="${failures}${item}(rc=${rc}) "
      failed=$((failed + 1))
    fi
  done
  printf 'aggregate failed=%d passed=%d\n' "$failed" "$passed"
  if [ "$failed" -gt 0 ]; then
    return 1
  fi
  return 0
}

main() {
  local rc=0
  run_batch || rc=$?
  printf 'batch exit: %d\n' "$rc"
  printf 'failed list: %s\n' "${failures% }"
}

main "$@"
