#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'depth 0: build failed' <<<"$out" || { echo "[assert] 未命中外层异常行"; fail=1; }
grep -q 'depth 1: checksum mismatch at offset 16' <<<"$out" || { echo "[assert] 未命中根因行（嵌套被剥开）"; fail=1; }
grep -q 'plain: no nested exception' <<<"$out" || { echo "[assert] 未命中普通重抛对照行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
