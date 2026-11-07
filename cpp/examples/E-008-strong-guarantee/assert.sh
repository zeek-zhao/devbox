#!/usr/bin/env bash
# 断言：关键诊断行命中 + 退出码符合预期。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")"

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
grep -q 'failed: storage full' <<<"$out" || { echo "[assert] 未命中失败注入行"; fail=1; }
grep -q 'after: size=2 last=bob' <<<"$out" || { echo "[assert] 未命中强保证回滚证据行"; fail=1; }
grep -q 'weak: size=1 (state already changed)' <<<"$out" || { echo "[assert] 未命中基本保证对照行"; fail=1; }
[ "$rc" -eq 0 ] || { echo "[assert] 预期退出码 0，实际 $rc"; fail=1; }

[ "$fail" = 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
