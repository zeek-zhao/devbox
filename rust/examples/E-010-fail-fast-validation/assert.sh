#!/usr/bin/env bash
# E-010 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^valid batch: 2 requests applied, ids \[1, 2\] total 300$' <<<"$out" \
  || { echo "[assert] 合法批次应全部应用"; fail=1; }
grep -q '^invalid batch rejected before any side effect: invalid id at line 2: `bad`$' \
  <<<"$out" \
  || { echo "[assert] 非法批次应在副作用前被整体拒绝且指认到行"; fail=1; }
grep -q '^empty batch rejected: empty batch$' <<<"$out" \
  || { echo "[assert] 未命中空批次拒绝输出"; fail=1; }
grep -q '^bad amount rejected: invalid amount at line 2$' <<<"$out" \
  || { echo "[assert] 未命中金额字段拒绝输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
