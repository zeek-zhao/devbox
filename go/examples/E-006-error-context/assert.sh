#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'context text: load profile "alice": dial 10.0.0.7:5432: operation timed out' <<<"$out" \
  || { echo "[assert] 未命中逐层上下文诊断行"; fail=1; }
grep -qF -e 'context keeps identity: errors.Is(err, ErrTimeout)=true' <<<"$out" \
  || { echo "[assert] 未命中身份保留行"; fail=1; }
grep -qF -e 'peel outer: dial 10.0.0.7:5432: operation timed out' <<<"$out" \
  || { echo "[assert] 未命中外层剥离行"; fail=1; }
grep -qF -e 'peel inner: operation timed out' <<<"$out" \
  || { echo "[assert] 未命中内层剥离行"; fail=1; }
grep -qF -e 'context quotes data: lookup "bobby; drop table users": user not found' <<<"$out" \
  || { echo "[assert] 未命中 %q 引住数据行"; fail=1; }
grep -qF -e 'context quotes keeps identity: errors.Is(safe, ErrNotFound)=true' <<<"$out" \
  || { echo "[assert] 未命中引住后身份保留行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
