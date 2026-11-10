#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"
rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'close: b' <<<"$out" || { echo "[assert] 未命中 b 关闭行"; fail=1; }
grep -qF -e 'close: a' <<<"$out" || { echo "[assert] 未命中 a 关闭行"; fail=1; }
# 逆序断言：b 必须在 a 之前关闭
line_a="$(grep -n 'close: a' <<<"$out" | cut -d: -f1)"
line_b="$(grep -n 'close: b' <<<"$out" | cut -d: -f1)"
[ "$line_b" -lt "$line_a" ] || { echo "[assert] 清理不是逆序：b 应先于 a 关闭"; fail=1; }
grep -qF -e 'caught: boom' <<<"$out" || { echo "[assert] 未命中捕获行"; fail=1; }
grep -qF -e 'suppress: continued after optional cleanup failure' <<<"$out" \
  || { echo "[assert] 未命中 suppress 续跑行"; fail=1; }
n="$(grep -c '' <<<"$out" || true)"
[ "$n" -eq 7 ] || { echo "[assert] 总行数期望 7，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
