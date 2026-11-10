#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'specific-first: FileNotFoundException caught: docs/7 missing' <<<"$out" \
  || { echo "[assert] 未命中具体类型优先行"; fail=1; }
grep -qF -e 'parent-catch: IOException caught: pipe broken' <<<"$out" \
  || { echo "[assert] 未命中父类捕获行"; fail=1; }
grep -qF -e 'union-catch: FileNotFoundException caught by union handler' <<<"$out" \
  || { echo "[assert] 未命中联合捕获行一"; fail=1; }
grep -qF -e 'union-then-parent: IOException caught by parent handler' <<<"$out" \
  || { echo "[assert] 未命中联合兜底行"; fail=1; }
grep -qF -e 'order-rule: subclass handlers must precede their base class' <<<"$out" \
  || { echo "[assert] 未命中顺序规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 5 ] || { echo "[assert] 总行数期望 5，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
