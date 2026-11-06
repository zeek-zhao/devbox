#!/usr/bin/env bash
# 断言：关键诊断行 + 退出码。用法：bash assert.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

out="$(bash run.sh 2>&1)"; rc=$?

fail=0
[ "$rc" -eq 0 ] || { echo "[assert] run.sh 退出码非 0：rc=$rc"; fail=1; }
grep -qF 'create errors.New: "input empty"' <<<"$out" \
  || { echo "[assert] 未命中 errors.New 创建行"; fail=1; }
grep -qF 'create fmt.Errorf: "connect 10.0.0.7:5432 attempt 3 failed"' <<<"$out" \
  || { echo "[assert] 未命中 fmt.Errorf 创建行"; fail=1; }
grep -qF 'typed-nil trap: ok case but err!=nil: true' <<<"$out" \
  || { echo "[assert] 未命中 typed-nil 陷阱行"; fail=1; }
grep -qF 'correct: return nil as error gives err==nil: true' <<<"$out" \
  || { echo "[assert] 未命中正确写法对照行"; fail=1; }
grep -qF 'create custom type: "port 70000 out of range 1..65535"' <<<"$out" \
  || { echo "[assert] 未命中自定义类型诊断行"; fail=1; }

[ "$fail" -eq 0 ] && echo "ASSERT-PASS" || { echo "ASSERT-FAIL"; exit 1; }
