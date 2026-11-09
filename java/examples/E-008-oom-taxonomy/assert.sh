#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'oom-triggered: java.lang.OutOfMemoryError caught' <<<"$out" \
  || { echo "[assert] 未命中 OOM 命中行"; fail=1; }
grep -qF -e 'oom-kind: heap-exhaustion -> action=raise-heap-or-fix-leak' <<<"$out" \
  || { echo "[assert] 未命中 OOM 分类行"; fail=1; }
grep -qF -e 'soe-triggered: java.lang.StackOverflowError caught' <<<"$out" \
  || { echo "[assert] 未命中 SOE 命中行"; fail=1; }
grep -qF -e 'soe-kind: call-depth -> action=fix-recursion' <<<"$out" \
  || { echo "[assert] 未命中 SOE 分类行"; fail=1; }
grep -qF -e 'taxonomy: fatal errors are classified by trigger' <<<"$out" \
  || { echo "[assert] 未命中结论行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
