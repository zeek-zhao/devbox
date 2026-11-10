#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^attempt=1 err=2003 class=environment retryable=yes$' <<<"$out" \
  || { echo "[assert] 未命中连接失败分类行"; fail=1; }
grep -q '^bad_password err=1045 class=credentials retryable=no$' <<<"$out" \
  || { echo "[assert] 未命中错误口令分类行"; fail=1; }
grep -q '^connect_ok=1$' <<<"$out" \
  || { echo "[assert] 未命中连接成功行"; fail=1; }
n="$(grep -c '^attempt=' <<<"$out" || true)"
[ "$n" -eq 3 ] || { echo "[assert] attempt= 行数期望 3，实际 $n"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
