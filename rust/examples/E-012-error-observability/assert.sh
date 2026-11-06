#!/usr/bin/env bash
# E-012 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^\[WARN\] row 2: parse failed (invalid digit found in string), degrading to id 0$' \
  <<<"$out" \
  || { echo "[assert] 未命中 stderr WARN 锚点行"; fail=1; }
grep -q '^\[ERROR\] row 4: parse failed (invalid digit found in string)$' \
  <<<"$out" \
  || { echo "[assert] 未命中 stderr ERROR 锚点行"; fail=1; }
grep -q '^-- stderr --$' <<<"$out" \
  || { echo "[assert] run.sh 应显式分隔 stdout 与 stderr"; fail=1; }
grep -q '^row 3: id 4$' <<<"$out" \
  || { echo "[assert] 未命中 row 3 成功输出"; fail=1; }
grep -q '^metrics: processed=3 warned=1 failed=1$' <<<"$out" \
  || { echo "[assert] 收尾计数应为 processed=3 warned=1 failed=1"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
