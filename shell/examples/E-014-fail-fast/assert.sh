#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
if [ "$rc" -ne 0 ]; then
  echo "[assert] run.sh 退出码非 0：rc=$rc"
  fail=1
fi
grep -qF -e 'mode=fail-fast missing-env: rc=2 work_done=0' <<<"$out" || {
  echo '[assert] 未命中前置拦截行'
  fail=1
}
grep -qF -e 'validate: missing ENV_API_URL' <<<"$out" || {
  echo '[assert] 未命中缺失项指名行'
  fail=1
}
grep -qF -e 'mode=blind: rc=3 work_done=0 (no validation at all)' <<<"$out" || {
  echo '[assert] 未命中盲跑对照行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
