#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^op=db-txn   by_code=LOCK_STALL  by_text=NET_TIMEOUT$' <<<"$out" \
  || { echo "[assert] 未命中文本误判反例行（锁等待被文本匹配误判为网络超时）"; fail=1; }
grep -q '^op=http-get by_code=NET_TIMEOUT by_text=NET_TIMEOUT$' <<<"$out" \
  || { echo "[assert] 未命中网络超时一致行"; fail=1; }
grep -q '^sentinel_err_is_matches=1$' <<<"$out" \
  || { echo "[assert] 未命中哨兵码比较行（应恰好命中 1 个）"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
