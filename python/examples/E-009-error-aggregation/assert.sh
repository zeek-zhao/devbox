#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'record 1: ok' <<<"$out" || { echo "[assert] 未命中成功记录行"; fail=1; }
grep -qF -e 'record 2: errors=2 name-empty age-negative' <<<"$out" \
  || { echo "[assert] 未命中多错误聚合行"; fail=1; }
grep -qF -e 'record 3: errors=1 age-out-of-range' <<<"$out" \
  || { echo "[assert] 未命中越界行"; fail=1; }
grep -qF -e 'record 4: errors=2 field-missing:name field-missing:age' <<<"$out" \
  || { echo "[assert] 未命中缺字段聚合行"; fail=1; }
grep -qF -e 'aggregate: bad=3 errors=5 -> report all, then reject' <<<"$out" \
  || { echo "[assert] 未命中汇总行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
