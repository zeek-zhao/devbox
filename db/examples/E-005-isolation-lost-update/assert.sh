#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^final_value=105$' <<<"$out" \
  || { echo "[assert] 未命中丢失更新结果行"; fail=1; }
grep -q '^lost_update=yes$' <<<"$out" \
  || { echo "[assert] 未命中丢失更新判定行"; fail=1; }
grep -q '^for_update_timeout err=1205 class=contention retryable=yes$' <<<"$out" \
  || { echo "[assert] 未命中锁等待超时归因行"; fail=1; }
grep -q '^retry_final=120$' <<<"$out" \
  || { echo "[assert] 未命中修复后重试行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
