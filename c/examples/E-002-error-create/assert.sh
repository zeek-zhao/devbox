#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^input=age=30 result=ok$' <<<"$out" \
  || { echo "[assert] 未命中成功路径行"; fail=1; }
grep -q '^input=age=-7 result=error code=1 what=age_negative' <<<"$out" \
  || { echo "[assert] 未命中 age_negative 错误行"; fail=1; }
grep -q 'what=age_unrealistic' <<<"$out" \
  || { echo "[assert] 未命中 age_unrealistic 错误行"; fail=1; }
n="$(grep -c 'result=error' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] 错误行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
