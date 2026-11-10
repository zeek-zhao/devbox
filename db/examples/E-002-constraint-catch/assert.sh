#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^dup_email err=1062 class=unique retryable=no$' <<<"$out" \
  || { echo "[assert] 未命中唯一约束归因行"; fail=1; }
grep -q '^negative_age err=3819 class=check retryable=no$' <<<"$out" \
  || { echo "[assert] 未命中检查约束归因行"; fail=1; }
grep -q '^orphan_order err=1452 class=foreign_key retryable=no$' <<<"$out" \
  || { echo "[assert] 未命中外键插入归因行"; fail=1; }
grep -q '^delete_parent err=1451 class=foreign_key retryable=no$' <<<"$out" \
  || { echo "[assert] 未命中外键删除归因行"; fail=1; }
grep -q '^insert_ok rows=1$' <<<"$out" \
  || { echo "[assert] 未命中修正后落库行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
