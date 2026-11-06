#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF -e 'swallow: caller sees success=true (cache miss lost)' <<<"$out" \
  || { echo "[assert] 未命中吞错反例行"; fail=1; }
grep -qF -e 'log-only: caller sees success=true log="ERROR load: cache miss"' <<<"$out" \
  || { echo "[assert] 未命中只记不抛反例行"; fail=1; }
grep -qF -e 'reraise: err=load: cache miss' <<<"$out" \
  || { echo "[assert] 未命中正确重抛行"; fail=1; }
grep -qF -e 'reraise keeps identity: errors.Is(err, ErrCacheMiss)=true' <<<"$out" \
  || { echo "[assert] 未命中重抛保身份行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
