#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -q '^ok path: invariant holds$' <<<"$out" \
  || { echo "[assert] 未命中正常路径行"; fail=1; }
grep -q '^FATAL invariant violated: main.c:[0-9]* (root->left > 0)$' <<<"$out" \
  || { echo "[assert] 未命中 FATAL 诊断行（应含文件、行号与不变量内容）"; fail=1; }
grep -q '^fatal_exit=70$' <<<"$out" \
  || { echo "[assert] 未命中固定退出码行（应为 70 = EX_SOFTWARE）"; fail=1; }
grep -q 'unreachable' <<<"$out" \
  && { echo "[assert] fatal 后不应继续执行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
