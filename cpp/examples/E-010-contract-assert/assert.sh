#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'empty: ok=false' <<<"$out" || { echo "[assert] 未命中空输入拒绝行"; fail=1; }
grep -q 'junk: ok=false' <<<"$out" || { echo "[assert] 未命中坏字符拒绝行"; fail=1; }
grep -q 'assert: active=true' <<<"$out" || { echo "[assert] 未命中 assert 生效性行（构建口径变了？）"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
