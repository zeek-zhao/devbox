#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'doc-1: ok' <<<"$out" || { echo "[assert] 未命中 doc-1 行"; fail=1; }
grep -qF -e 'doc-2: FAILED ValidationException (schema mismatch)' <<<"$out" \
  || { echo "[assert] 未命中 doc-2 失败行"; fail=1; }
grep -qF -e 'doc-3: ok' <<<"$out" || { echo "[assert] 未命中 doc-3 行"; fail=1; }
grep -qF -e 'doc-4: FAILED TransientException (storage busy)' <<<"$out" \
  || { echo "[assert] 未命中 doc-4 失败行"; fail=1; }
grep -qF -e 'aggregate: ok=2 failed=2 -> collect all failures before deciding' <<<"$out" \
  || { echo "[assert] 未命中汇总行"; fail=1; }
grep -qF -e 'rule: per-task failures are recorded, then reported once' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 6 ] || { echo "[assert] 总行数期望 6，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
