#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'lbyl-hit: got 3' <<<"$out" || { echo "[assert] 未命中 LBYL 命中行"; fail=1; }
grep -qF -e 'lbyl-miss: default' <<<"$out" || { echo "[assert] 未命中 LBYL 缺失行"; fail=1; }
grep -qF -e 'eafp-hit: got 3' <<<"$out" || { echo "[assert] 未命中 EAFP 命中行"; fail=1; }
grep -qF -e 'eafp-miss: default' <<<"$out" || { echo "[assert] 未命中 EAFP 缺失行"; fail=1; }
grep -qF -e 'verdict: EAFP collapses check and use into one step' <<<"$out" \
  || { echo "[assert] 未命中结论行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
