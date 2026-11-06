#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^\[reraise\] top sees code=9 -> fail over to replica$' <<<"$out" \
  || { echo "[assert] 未命中重抛路径顶层行（码 9 应到达顶层）"; fail=1; }
grep -q '^\[swallow\] top sees success (code=0)$' <<<"$out" \
  || { echo "[assert] 未命中吞错对照行（顶层误判成功正是反例后果）"; fail=1; }
grep -q 'SWALLOWED' <<<"$out" || { echo "[assert] 未命中吞错标记"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
