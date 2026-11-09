#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'implicit: type=RuntimeError cause=None context=ValueError' <<<"$out" \
  || { echo "[assert] 未命中隐式链行"; fail=1; }
grep -qF -e 'explicit: type=RuntimeError cause=ValueError context=ValueError' <<<"$out" \
  || { echo "[assert] 未命中显式链行"; fail=1; }
grep -qF -e 'bare-reraise: same-object=True cause=None' <<<"$out" \
  || { echo "[assert] 未命中裸重抛行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] 总行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
