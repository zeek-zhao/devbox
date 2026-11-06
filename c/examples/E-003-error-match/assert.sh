#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^sim=1 matched=EXACT code=3 outcome=create-default-record$' <<<"$out" \
  || { echo "[assert] 未命中 NOT_FOUND 精确匹配行"; fail=1; }
grep -q '^sim=2 matched=EXACT code=4 outcome=retry-later$' <<<"$out" \
  || { echo "[assert] 未命中 TIMEOUT 精确匹配行"; fail=1; }
grep -q '^sim=3 matched=FALLBACK code=5 outcome=escalate$' <<<"$out" \
  || { echo "[assert] 未命中兜底分支行"; fail=1; }
n="$(grep -c 'matched=' <<<"$out" || true)"
[ "$n" -eq 4 ] || { echo "[assert] matched= 行数期望 4，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
