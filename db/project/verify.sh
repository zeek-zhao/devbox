#!/usr/bin/env bash
# 毕业项目统一验证入口（#394 · M13-CONTENT-01）
#
# db 轨没有「构建」这一步：项目跑在宿主，经 docker compose exec 进 toolbox。
# 判定 = 「栈就绪 → 端到端跑通 → 输出非空」。
# 用法：先 db/scripts/up.sh && db/scripts/wait-ready.sh，再 bash db/project/verify.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$ROOT/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$REPO" || exit 2

pass=0
total=0
check() {
  local name="$1"
  shift
  total=$((total + 1))
  if "$@"; then
    pass=$((pass + 1))
    printf '[pass] %s\n' "$name" >&2
  else
    printf '[fail] %s\n' "$name" >&2
  fi
}

check "project/run.sh 存在" test -f "$ROOT/run.sh"

ready_ok=0
if bash db/scripts/wait-ready.sh >"$WORK/ready.log" 2>&1; then
  ready_ok=1
else
  tail -10 "$WORK/ready.log"
fi
check "五库栈就绪（wait-ready.sh）" test "$ready_ok" -eq 1

run_ok=0
if [ "$ready_ok" -eq 1 ]; then
  if bash "$ROOT/run.sh" >"$WORK/self.log" 2>&1; then
    run_ok=1
  else
    tail -20 "$WORK/self.log"
  fi
fi
check "端到端跑通（project/run.sh）" test "$run_ok" -eq 1
check "端到端输出非空" test -s "$WORK/self.log"

printf '%d/%d 判定符合预期\n' "$pass" "$total" >&2
[ "$pass" -eq "$total" ]
