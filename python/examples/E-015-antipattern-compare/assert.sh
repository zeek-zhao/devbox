#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'anti-1: kept going (failure swallowed, bug invisible) -> wrong' <<<"$out" \
  || { echo "[assert] 未命中吞错反例行"; fail=1; }
grep -qF -e 'fix-1: {"code": "INTERNAL", "message": "disk-full"} -> logged, visible' <<<"$out" \
  || { echo "[assert] 未命中结构化修复行"; fail=1; }
grep -qF -e 'anti-2: other (classified by message text) -> wrong' <<<"$out" \
  || { echo "[assert] 未命中文本分流反例行"; fail=1; }
grep -qF -e 'fix-2: INTERNAL (classified by type) -> stable' <<<"$out" \
  || { echo "[assert] 未命中类型分流修复行"; fail=1; }
grep -qF -e 'anti-3: caught (wrong: bare except also swallows Ctrl-C)' <<<"$out" \
  || { echo "[assert] 未命中裸 except 反例行"; fail=1; }
grep -qF -e 'fix-3: escaped to caller (right: Ctrl-C not swallowed)' <<<"$out" \
  || { echo "[assert] 未命中中断逃逸修复行"; fail=1; }
grep -qF -e 'rule: never swallow silently' <<<"$out" \
  || { echo "[assert] 未命中规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 7 ] || { echo "[assert] 总行数期望 7，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
