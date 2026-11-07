#!/usr/bin/env bash
# E-006 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^top context: loading document for search index$' <<<"$out" \
  || { echo "[assert] 未命中顶层上下文"; fail=1; }
grep -q '^next layer: parsing document id from `seven`$' <<<"$out" \
  || { echo "[assert] 未命中中层上下文"; fail=1; }
grep -q '^root cause: invalid digit found in string$' <<<"$out" \
  || { echo "[assert] 未命中根因（source 链末端）"; fail=1; }
grep -q '^context stack depth: 3$' <<<"$out" \
  || { echo "[assert] 上下文栈深度应为 3（两层语境 + 根因）"; fail=1; }
grep -q '^ok path: id 42$' <<<"$out" \
  || { echo "[assert] 未命中成功路径输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
