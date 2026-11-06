#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^code=5 name=NO_MEMORY category=INTERNAL$' <<<"$out" \
  || { echo "[assert] 未命中 NO_MEMORY -> INTERNAL 分类行"; fail=1; }
grep -q '^code=4 name=TIMEOUT category=ENVIRONMENT$' <<<"$out" \
  || { echo "[assert] 未命中 TIMEOUT -> ENVIRONMENT 分类行"; fail=1; }
grep -q '^taxonomy codes=6 usage=2 environment=2 internal=1$' <<<"$out" \
  || { echo "[assert] 未命中分类汇总行"; fail=1; }
n="$(grep -c '^code=' <<<"$out" || true)"
[ "$n" -eq 6 ] || { echo "[assert] code= 行数期望 6，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
