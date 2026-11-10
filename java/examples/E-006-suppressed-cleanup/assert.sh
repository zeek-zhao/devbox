#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'manual-finally: surfaced=IllegalStateException suppressed-count=0 (business error masked by close failure)' <<<"$out" \
  || { echo "[assert] 未命中手动 finally 遮盖行"; fail=1; }
grep -qF -e 'twr: surfaced=BusinessError suppressed=[IllegalStateException]' <<<"$out" \
  || { echo "[assert] 未命中 try-with-resources 行"; fail=1; }
grep -qF -e 'rule: cleanup failure must not mask the original error' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] 总行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
