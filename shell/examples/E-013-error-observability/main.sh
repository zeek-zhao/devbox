#!/usr/bin/env bash
# 可观测性：失败不仅要有退出码，还要留下机器可读的结构化记录
# （step/status/rc/reason），供日志管道聚合；stdout 只留业务结果。
set -euo pipefail

REPORT=''

record() {
  # 追加一条结构化记录（\n 由最后统一 printf %b 展开成真实换行）。
  local step="$1" status="$2" rc="$3" reason="$4"
  REPORT="${REPORT}step=${step} status=${status} rc=${rc} reason=${reason}"$'\n'
}

deploy_step() {
  case "$1" in
    download) return 3 ;;
    *) return 0 ;;
  esac
}

step_reason() {
  # 失败原因的归类（真脚本里来自错误分类，见 E-001）。
  case "$1" in
    download) printf 'network' ;;
    *) printf 'none' ;;
  esac
}

run_deploy() {
  local step rc reason
  local ok=0
  local bad=0
  for step in build download test publish; do
    rc=0
    deploy_step "$step" || rc=$?
    if [ "$rc" -eq 0 ]; then
      record "$step" ok 0 none
      ok=$((ok + 1))
    else
      reason="$(step_reason "$step")"
      record "$step" failed "$rc" "$reason"
      bad=$((bad + 1))
    fi
  done
  printf 'deploy result: ok=%d failed=%d\n' "$ok" "$bad"
}

main() {
  run_deploy
  printf '%s' "$REPORT"
}

main "$@"
