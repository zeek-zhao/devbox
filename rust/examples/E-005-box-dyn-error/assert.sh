#!/usr/bin/env bash
# E-005 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^record 0: id 42$' <<<"$out" \
  || { echo "[assert] 未命中成功记录输出"; fail=1; }
grep -q '^record 1: malformed -> skip entry$' \
  <<<"$out" \
  || { echo "[assert] 未命中自定义错误 downcast 分支"; fail=1; }
grep -q '^record 2: parse failure on port -> use default id 0$' \
  <<<"$out" \
  || { echo "[assert] 未命中 ParseIntError downcast 分支"; fail=1; }
grep -q '^heterogeneous errors handled at one boundary: 2$' \
  <<<"$out" \
  || { echo "[assert] 未命中边界统一处理计数"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
