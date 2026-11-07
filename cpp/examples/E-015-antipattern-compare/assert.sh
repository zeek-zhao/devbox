#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'ANTI swallow: caller saw nothing' <<<"$out" || { echo "[assert] 未命中吞异常反模式行"; fail=1; }
grep -q 'ANTI slicing: what=rich error' <<<"$out" || { echo "[assert] 未命中切片反模式行"; fail=1; }
grep -q 'GOOD ref: what=rich error seq=77' <<<"$out" || { echo "[assert] 未命中引用捕获保真行（seq 字段应保留）"; fail=1; }
grep -q 'GOOD context: build: open /data/index.bin: errno=2' <<<"$out" || { echo "[assert] 未命中上下文保留行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
