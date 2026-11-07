#!/usr/bin/env bash
# E-007 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^aggregated: 3 ok, 2 failed$' <<<"$out" \
  || { echo "[assert] 聚合计数应为 3 成功 2 失败"; fail=1; }
grep -q '^failed: row 1: invalid digit found in string$' <<<"$out" \
  || { echo "[assert] 未命中第 1 行失败报告"; fail=1; }
grep -q '^failed: row 3: invalid digit found in string$' <<<"$out" \
  || { echo "[assert] 未命中第 3 行失败报告（聚合要求两条都报）"; fail=1; }
grep -q '^all-or-nothing short-circuits: true$' <<<"$out" \
  || { echo "[assert] 未命中 collect 短路对照"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
