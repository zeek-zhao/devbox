#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^tail_marker good=yes bad=no$' <<<"$out" \
  || { echo "[assert] 未命中尾部标记检测行"; fail=1; }
grep -q '^corrupt_restore stmts_done=17 err=1064 detected=yes$' <<<"$out" \
  || { echo "[assert] 未命中坏副本恢复 1064 行"; fail=1; }
grep -q '^good_restore rows=3 checksum_match=yes$' <<<"$out" \
  || { echo "[assert] 未命中完好副本恢复验收行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
