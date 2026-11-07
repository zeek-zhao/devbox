#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF 'identity: two errors.New with same text identical: false' <<<"$out" \
  || { echo "[assert] 未命中 errors.New 身份不同行"; fail=1; }
grep -qF 'identity: wrapped sentinel via errors.Is: true' <<<"$out" \
  || { echo "[assert] 未命中 sentinel 同一身份行"; fail=1; }
grep -qF 'as: extracted *ParseError ok=true field="age" line=3' <<<"$out" \
  || { echo "[assert] 未命中 errors.As 提取行"; fail=1; }
grep -qF 'as: second same-class ok=true field="age" line=9' <<<"$out" \
  || { echo "[assert] 未命中同类不同值行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
