#!/usr/bin/env bash
# T-001-venv-mix-mutable-default 断言：关键诊断行命中 + 退出码符合预期 + 路径归一化。
# docs/72 §2 样板扩展版：两段断言——最小复现（venvB ModuleNotFoundError）与完整演练。
# 用法：bash assert.sh ；连跑两次结论必须一致；退出非零 = 红。
set -uo pipefail
cd "$(dirname "$0")" || exit

BUILD="${TMPDIR:-/tmp}/devbox-python-T-001-venv-mix-mutable-default"
fail=0

# ---- 第 1 段：最小复现。按 docs/72 真本：故障被触发 = 非零退出码。
out="$(bash repro.sh 2>&1)"
rc=$?
grep -q 'ModuleNotFoundError: No module named' <<<"$out" ||
  {
    echo "[assert] 未命中 ModuleNotFoundError 诊断行"
    fail=1
  }
grep -q 'Traceback (most recent call last)' <<<"$out" ||
  {
    echo "[assert] 未命中 Traceback 头（可能不是以异常路径失败）"
    fail=1
  }
[ "$rc" -ne 0 ] || {
  echo "[assert] 预期非零退出码，实际 0（故障未被触发）"
  fail=1
}

# ---- 第 2 段：完整演练。run.sh 内部已做逐步判定，全过 = 退出 0。
tout="$(bash run.sh 2>&1)"
trc=$?
[ "$trc" -eq 0 ] || {
  echo "[assert] run.sh 应全绿退出 0，实际 $trc"
  tail -20 <<<"$tout" >&2
  fail=1
}
grep -q 'B006' <<<"$tout" ||
  {
    echo "[assert] 未命中 ruff B006 定位行（可变默认参数未被钉到行）"
    fail=1
  }
grep -q 'myproj=1.0.0-venvA' <<<"$tout" ||
  {
    echo "[assert] 未命中 venvA 健康对照行 myproj=1.0.0-venvA"
    fail=1
  }
grep -q 'ModuleNotFoundError: No module named' <<<"$tout" ||
  {
    echo "[assert] 未命中 venvB 缺陷诊断行 ModuleNotFoundError"
    fail=1
  }
grep -q 'externally-managed-environment' <<<"$tout" ||
  {
    echo "[assert] 未命中 PEP 668 防线行 externally-managed-environment"
    fail=1
  }
grep -q "cart call1=\['apple', 'banana'\]" <<<"$tout" ||
  {
    echo "[assert] 未命中可变默认参数残留行 cart call1=..."
    fail=1
  }

# ---- 归一化后复断言：容器内临时路径 → <BUILD> 占位符，禁止逐字比对整段输出。
norm="$(sed -E "s#$BUILD#<BUILD>#g" <<<"$out")"
grep -q 'sys.executable=<BUILD>/venvB/bin/python' <<<"$norm" ||
  {
    echo "[assert] 归一化后未命中解释器对照行（venv 路径证据缺失）"
    fail=1
  }
[ -n "$norm" ] || fail=1

if [ "$fail" = 0 ]; then
  echo "ASSERT-PASS"
else
  echo "ASSERT-FAIL"
  exit 1
fi
