#!/usr/bin/env bash
# 快速失败：先集中校验前置条件（必需环境），再开始任何实际工作。
# 第一个缺失即停；对照「边跑边炸」——校验缺位时失败来得又晚又模糊。
set -euo pipefail

ENV_API_URL=''
ENV_TOKEN=''
work_done=0

validate_all() {
  # 集中校验：返回 0=前置齐备；第一个缺失即以 2 退出并指名缺什么。
  local need value
  for need in ENV_API_URL ENV_TOKEN; do
    value="${!need}"
    if [ -z "$value" ]; then
      printf 'validate: missing %s\n' "$need" >&2
      return 2
    fi
  done
  return 0
}

do_work() {
  if [ -z "$ENV_API_URL" ]; then
    printf 'work: aborted: endpoint missing mid-run\n' >&2
    return 3
  fi
  work_done=$((work_done + 1))
  return 0
}

main() {
  local rc=0
  # 场景一：前置校验拦住缺失的 API 地址，一行工作都没跑。
  ENV_API_URL=''
  ENV_TOKEN='token-1'
  work_done=0
  validate_all || rc=$?
  printf 'mode=fail-fast missing-env: rc=%d work_done=%d\n' "$rc" "$work_done"
  # 场景二：前置齐备，正常开工。
  ENV_API_URL='https://example.invalid'
  work_done=0
  rc=0
  validate_all || rc=$?
  if [ "$rc" -eq 0 ]; then
    do_work || rc=$?
  fi
  printf 'mode=fail-fast env-ok: rc=%d work_done=%d\n' "$rc" "$work_done"
  # 对照：不做校验直接开工，撞在半路。
  ENV_API_URL=''
  work_done=0
  rc=0
  do_work || rc=$?
  printf 'mode=blind: rc=%d work_done=%d (no validation at all)\n' "$rc" "$work_done"
}

main "$@"
