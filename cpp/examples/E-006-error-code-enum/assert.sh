#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'empty: bad input exit=1' <<<"$out" || { echo "[assert] 未命中输入错误退出行"; fail=1; }
grep -q 'ghost: not found exit=0' <<<"$out" || { echo "[assert] 未命中业务失败退出行"; fail=1; }
grep -q 'ghost: raw=4' <<<"$out" || { echo "[assert] 未命中枚举显式取值行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
