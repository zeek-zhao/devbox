#!/usr/bin/env bash
# E-004 断言：关键诊断行命中 + 退出码符合预期（docs/72 §2 样板）。
# 用法：bash assert.sh；退出 0 = 通过，非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

fail=0

out="$(bash run.sh 2>&1)"
rc=$?

[ "$rc" -eq 0 ] || { echo "[assert] run.sh 应退出 0，实际 $rc"; fail=1; }
grep -q '^ok path equal: true$' <<<"$out" \
  || { echo "[assert] ?与 map_err 成功路径应等价"; fail=1; }
grep -q '^err path equal: true$' <<<"$out" \
  || { echo "[assert] ?与 map_err 错误路径应等价"; fail=1; }
grep -q '^question-mark is From::from: true$' <<<"$out" \
  || { echo "[assert] 未命中 ?即 From::from 的取证"; fail=1; }
grep -q '^display keeps root cause: config port: invalid digit found in string$' <<<"$out" \
  || { echo "[assert] 未命中 Display 保留根因输出"; fail=1; }

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
