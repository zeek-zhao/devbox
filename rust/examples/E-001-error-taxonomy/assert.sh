#!/usr/bin/env bash
# E-001 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q 'recoverable: Err -> fallback port 0' <<<"$out" \
  || { echo "[assert] 未命中可恢复分支回退输出"; fail=1; }
grep -q 'recoverable: Ok -> port 8080' <<<"$out" \
  || { echo "[assert] 未命中可恢复分支成功输出"; fail=1; }
grep -q 'unrecoverable: invariant panic caught = true' <<<"$out" \
  || { echo "[assert] 未命中不可恢复分支 panic 取证"; fail=1; }
grep -q 'taxonomy: recoverable=Result, unrecoverable=panic' <<<"$out" \
  || { echo "[assert] 未命中分类结论行"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
