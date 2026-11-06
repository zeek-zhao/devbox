#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'level=ERROR msg="request failed" err="service: repo unavailable" op=list-users' <<<"$out" \
  || { echo "[assert] 未命中边界结构化记录行"; fail=1; }
grep -qF -e 'level=ERROR msg="repo failed" layer=service' <<<"$out" \
  || { echo "[assert] 未命中中间层重复记录反例行"; fail=1; }
grep -qF -e 'observability: errors.Is after logging=true' <<<"$out" \
  || { echo "[assert] 未命中日志不影响判定行"; fail=1; }
n="$(grep -c 'level=ERROR' <<<"$out" || true)"
[ "$n" -eq 2 ] || { echo "[assert] level=ERROR 行数期望 2（正解 1 条 + 反例 1 条），实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
