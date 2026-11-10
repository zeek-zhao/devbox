#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^race_commit err=1062 action=adopt_existing$' <<<"$out" \
  || { echo "[assert] 未命中竞态 1062 归因行"; fail=1; }
grep -q '^adopted sku=widget-b qty=1$' <<<"$out" \
  || { echo "[assert] 未命中采用既有行输出"; fail=1; }
grep -q '^race_rollback loser_ok=yes$' <<<"$out" \
  || { echo "[assert] 未命中竞态翻转输出"; fail=1; }
grep -q '^upsert_concurrent qty=110 lost_update=no$' <<<"$out" \
  || { echo "[assert] 未命中并发 upsert 不丢更新行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
