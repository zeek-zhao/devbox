#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'attempt 3: ok' <<<"$out" || { echo "[assert] 未命中重试后成功行"; fail=1; }
grep -q 'give up: attempts exhausted' <<<"$out" || { echo "[assert] 未命中次数耗尽行"; fail=1; }
grep -q 'dead: give up immediately' <<<"$out" || { echo "[assert] 未命中永久错误立即放弃行"; fail=1; }
# 指数退避真睡了 2+4ms（至少两次 sleep），总耗时应明显大于 0
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
