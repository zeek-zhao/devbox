#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'retry success: attempts=3 waited=30ms err=<nil>' <<<"$out" \
  || { echo "[assert] 未命中重试成功行"; fail=1; }
grep -qF -e 'retry non-retryable: attempts=1 waited=0s err=not retryable: quota exceeded' <<<"$out" \
  || { echo "[assert] 未命中不可重试即停行"; fail=1; }
grep -qF -e 'retry give-up: attempts=4 waited=70ms err=gave up after 4 attempts: rate limited at attempt 4' <<<"$out" \
  || { echo "[assert] 未命中预算耗尽行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
