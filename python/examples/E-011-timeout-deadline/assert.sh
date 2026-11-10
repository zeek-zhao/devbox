#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'deadline-hit: TimeoutError after 0.05s' <<<"$out" \
  || { echo "[assert] 未命中超时命中行"; fail=1; }
grep -qF -e 'deadline-class: TIMEOUT -> action=cancel-and-report' <<<"$out" \
  || { echo "[assert] 未命中超时分类行"; fail=1; }
grep -qF -e 'fast-path: got done' <<<"$out" \
  || { echo "[assert] 未命中快速路径行"; fail=1; }
grep -qF -e 'rule: every wait has a deadline' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 4 ] || { echo "[assert] 总行数期望 4，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
