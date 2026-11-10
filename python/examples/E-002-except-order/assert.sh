#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e "specific-first: ValueError: invalid literal for int() with base 10: 'x'" <<<"$out" \
  || { echo "[assert] 未命中具体类型优先行"; fail=1; }
grep -qF -e 'tuple-catch: KeyError' <<<"$out" \
  || { echo "[assert] 未命中元组捕获行"; fail=1; }
grep -qF -e 'fallback-last: Exception: RuntimeError: boom' <<<"$out" \
  || { echo "[assert] 未命中宽兜底行"; fail=1; }
grep -qF -e 'order-rule: except clauses are tried top-down' <<<"$out" \
  || { echo "[assert] 未命中顺序规则行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 4 ] || { echo "[assert] 总行数期望 4，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
