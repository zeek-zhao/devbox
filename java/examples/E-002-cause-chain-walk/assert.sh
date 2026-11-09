#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'top: ImportException: import doc-7 failed' <<<"$out" \
  || { echo "[assert] 未命中顶层异常行"; fail=1; }
grep -qF -e 'layer-2 cause: StorageException: read path docs/7' <<<"$out" \
  || { echo "[assert] 未命中中层 cause 行"; fail=1; }
grep -qF -e 'root cause: java.io.IOException: sector unreadable' <<<"$out" \
  || { echo "[assert] 未命中根因行"; fail=1; }
grep -qF -e 'chain-depth: 3' <<<"$out" \
  || { echo "[assert] 未命中链深行"; fail=1; }
grep -qF -e 'rule: wrap at boundaries, keep the cause, walk to the root' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
