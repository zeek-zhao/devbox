#!/usr/bin/env bash
# E-009 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^collect all: true$' <<<"$out" \
  || { echo "[assert] collect 应在首错处短路为 Err"; fail=1; }
grep -q '^try_fold: short-circuited$' <<<"$out" \
  || { echo "[assert] try_fold 应在首个错误处短路"; fail=1; }
grep -q '^ok-only: \[2, 4, 8\]$' <<<"$out" \
  || { echo "[assert] filter_map(Result::ok) 应只留成功项"; fail=1; }
grep -q '^partition: 3 ok, 1 err$' <<<"$out" \
  || { echo "[assert] 分区计数应为 3 成功 1 失败"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
