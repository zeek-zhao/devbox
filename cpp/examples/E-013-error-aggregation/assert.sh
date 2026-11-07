#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'bad input: 3 problems' <<<"$out" || { echo "[assert] 未命中三错聚合计数行"; fail=1; }
grep -q '  - port: must be numeric' <<<"$out" || { echo "[assert] 未命中 port 字段诊断行"; fail=1; }
grep -q 'valid input: 0 problems' <<<"$out" || { echo "[assert] 未命中空列表成功信号行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
