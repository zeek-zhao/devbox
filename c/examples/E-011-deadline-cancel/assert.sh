#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^deadline hit after 3 steps$' <<<"$out" \
  || { echo "[assert] 未命中 deadline 触发行（预算应为 3 步）"; fail=1; }
grep -q '^deadline code=4 completed_steps=3$' <<<"$out" \
  || { echo "[assert] 未命中 deadline 收场行"; fail=1; }
grep -q '^cancel observed at safe point$' <<<"$out" \
  || { echo "[assert] 未命中取消安全点行"; fail=1; }
grep -q '^cancel code=6 completed_steps=2$' <<<"$out" \
  || { echo "[assert] 未命中 cancel 收场行（应在第 2 步后退出）"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
