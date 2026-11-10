#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^delete_parent err=1451 class=foreign_key action=handle_children$' <<<"$out" \
  || { echo "[assert] 未命中 1451 护栏行"; fail=1; }
grep -q '^explicit_two_step orders_left=0 customer_gone=yes$' <<<"$out" \
  || { echo "[assert] 未命中显式两步删除行"; fail=1; }
grep -q '^cascade_delete invoices_before=2 invoices_after=0 silent_loss=yes$' <<<"$out" \
  || { echo "[assert] 未命中级联静默丢失行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
