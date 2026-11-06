#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'timeout: err=handle: query: context deadline exceeded' <<<"$out" \
  || { echo "[assert] 未命中超时诊断行"; fail=1; }
grep -qF -e 'timeout identity: errors.Is(err, context.DeadlineExceeded)=true' <<<"$out" \
  || { echo "[assert] 未命中 DeadlineExceeded 判定行"; fail=1; }
grep -qF -e 'cancel: err=handle: query: context canceled' <<<"$out" \
  || { echo "[assert] 未命中取消诊断行"; fail=1; }
grep -qF -e 'cancel identity: errors.Is(err, context.Canceled)=true' <<<"$out" \
  || { echo "[assert] 未命中 Canceled 判定行"; fail=1; }
grep -qF -e 'enough budget: err=<nil>' <<<"$out" \
  || { echo "[assert] 未命中预算充足成功行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
