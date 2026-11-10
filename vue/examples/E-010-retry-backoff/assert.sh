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
grep -qF -e 'retry success: attempts=3 waited=30ms result=payload' <<<"$out" || {
  echo '[assert] 未命中重试成功行'
  fail=1
}
grep -qF -e 'retry non-retryable: attempts=1 waited=0ms result=E_PERM' <<<"$out" || {
  echo '[assert] 未命中不可重试即停行'
  fail=1
}
grep -qF -e 'retry give-up: attempts=4 waited=70ms result=E_TRANSIENT' <<<"$out" || {
  echo '[assert] 未命中预算耗尽行'
  fail=1
}

if [ "$fail" -eq 0 ]; then
  echo 'ASSERT-PASS'
else
  echo 'ASSERT-FAIL'
  exit 1
fi
