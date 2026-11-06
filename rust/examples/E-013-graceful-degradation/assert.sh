#!/usr/bin/env bash
# E-013 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^query `42` -> 42 via primary$' <<<"$out" \
  || { echo "[assert] 主路径应直接命中"; fail=1; }
grep -q '^query ` 7 ` -> 7 via replica$' <<<"$out" \
  || { echo "[assert] 主路径失败应降级到备用路径且留标签"; fail=1; }
grep -q '^query `gone` -> 0 via default$' <<<"$out" \
  || { echo "[assert] 备用路径失败应降级到默认值且留标签"; fail=1; }
grep -q '^unwrap_or_else default: 0$' <<<"$out" \
  || { echo "[assert] 未命中 unwrap_or_else 惯用法输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
