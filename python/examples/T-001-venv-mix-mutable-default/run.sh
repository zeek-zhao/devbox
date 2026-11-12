#!/usr/bin/env bash
# T-001-venv-mix-mutable-default 演练入口：ruff 静态基线 → B006 定位 → venvA 健康对照 →
# venvB 触发 ModuleNotFoundError → PYTHONPATH 串味复现 → PEP 668 防线 →
# 可变默认参数残留判读，七步串完整流程。
# 工具（python3 venv / pip / ruff）预装在 devbox-python 镜像里，
# 请在容器内运行，例如：
#   docker run --rm -v "$PWD":/w -w /w \
#     ghcr.io/zeek-zhao/devbox-python:latest \
#     bash python/examples/T-001-venv-mix-mutable-default/run.sh
# 产物只写临时目录，不入库。用法：bash run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

PY="${PY:-python3}"
RUFF="${RUFF:-ruff}"
BUILD="${TMPDIR:-/tmp}/devbox-python-T-001-venv-mix-mutable-default"
VENV_A="$BUILD/venvA"
VENV_B="$BUILD/venvB"
mkdir -p "$BUILD"
# 展示归一化：容器内临时路径虽两次运行一致，仍统一打成占位符（docs/72 §2）。
norm() { sed -E "s#$BUILD#<BUILD>#g"; }

pass=0
step() {
  echo
  echo "=== [step $1] $2 ==="
}
ok() {
  echo "  -> 符合预期"
  pass=$((pass + 1))
}
bad() { echo "  -> 不符合预期：$1" >&2; }

setup_venvs() {
  if [ ! -x "$VENV_A/bin/python" ]; then
    "$PY" -m venv "$VENV_A" || {
      echo "venvA 创建失败" >&2
      exit 2
    }
  fi
  if [ ! -x "$VENV_B/bin/python" ]; then
    "$PY" -m venv "$VENV_B" || {
      echo "venvB 创建失败" >&2
      exit 2
    }
  fi
  sp_a="$(ls -d "$VENV_A"/lib/python3*/site-packages 2>/dev/null | head -1)"
  if [ -z "$sp_a" ]; then
    echo "未找到 venvA site-packages（镜像/Python 版本漂移，停止并交维护者）" >&2
    exit 2
  fi
  cat >"$BUILD/myproj.py" <<'PYEOF'
"""myproj · 本 lab 的占位第三方包，只存在于 venvA 的 site-packages。"""

VERSION = "1.0.0-venvA"
PYEOF
  cp "$BUILD/myproj.py" "$sp_a/myproj.py" || exit 2
}

setup_venvs

step 1 "ruff check（默认规则集）：静态基线全绿，两个缺陷照样在场"
rlog="$BUILD/ruff-default.log"
if "$RUFF" check --cache-dir "$BUILD/ruff-cache" main.py >"$rlog" 2>&1; then
  ok
  echo "  (默认 E/F/W 规则集对这两个缺陷天然失明：可变默认参数属 flake8-bugbear B006，"
  echo "   不在默认集；环境串味是运行时属性，静态分析根本看不见。别把 lint 绿当结案证据)"
else
  bad "ruff check 应退出 0（缺陷不在默认规则射程内）；实际报错："
  sed 's/^/  | /' "$rlog"
fi

step 2 "ruff check --select B006：换检测器把可变默认参数钉到行"
blog="$BUILD/ruff-b006.log"
"$RUFF" check --cache-dir "$BUILD/ruff-cache" --select B006 main.py >"$blog" 2>&1
brc=$?
grep 'B006' "$blog" | sed 's/^/  | /'
if [ "$brc" -ne 0 ] && grep -q 'B006' "$blog"; then
  ok
  echo "  (同一缺陷、第二个检测器就现形：--select B006 精确指到 items=[] 的定义行，"
  echo "   与 step 7 的运行时残留互为两份独立证据)"
else
  bad "ruff --select B006 应非零退出且报出 B006；实际 rc=$brc"
fi

step 3 "venvA 健康对照：同一段代码，包装对了环境就 import 成功"
alog="$BUILD/venva.log"
"$VENV_A/bin/python" main.py >"$alog" 2>&1
arc=$?
grep -E 'env: start|sys.executable|cart call|myproj=' "$alog" | norm | sed 's/^/  | /'
if [ "$arc" -eq 0 ] && grep -q 'myproj=1.0.0-venvA' "$alog"; then
  ok
  echo "  (venvA 退出 0、myproj 正常 import——代码没变，变的只是环境，先立健康基线)"
else
  bad "venvA 应退出 0 且打印 myproj=1.0.0-venvA；实际 rc=$arc"
  sed 's/^/  | /' "$alog" | head -20
fi

step 4 "venvB 触发缺陷：ModuleNotFoundError（症状一）"
vlog="$BUILD/venvb.log"
"$VENV_B/bin/python" main.py >"$vlog" 2>&1
vrc=$?
grep -E 'Traceback|File |ModuleNotFoundError' "$vlog" | norm | sed 's/^/  | /'
if [ "$vrc" -ne 0 ] && grep -q 'ModuleNotFoundError: No module named' "$vlog"; then
  ok
  echo "  (venvB 的解释器 + 同一份 main.py = 崩在 load_myproj 的 import myproj（main.py:21）——"
  echo "   与 step 3 对照即可断定问题在环境不在代码)"
else
  bad "venvB 应非零退出且报 ModuleNotFoundError；实际 rc=$vrc"
  sed 's/^/  | /' "$vlog" | head -20
fi

step 5 "PYTHONPATH 串味复现：venvB 从 venvA「借」到包（症状二）"
clog="$BUILD/mix.log"
PYTHONPATH="$sp_a" "$VENV_B/bin/python" main.py >"$clog" 2>&1
crc=$?
grep -E 'myproj=' "$clog" | norm | sed 's/^/  | /'
PYTHONPATH="$sp_a" "$VENV_B/bin/python" -c "import myproj; print('myproj.__file__=' + myproj.__file__)" |
  norm | sed 's/^/  | /'
if [ "$crc" -eq 0 ] && grep -q 'myproj=1.0.0-venvA' "$clog"; then
  ok
  echo "  (包明明只装在 venvA，venvB 却 import 成功——PYTHONPATH 就是串味通道，"
  echo "   myproj.__file__ 指向 venvA 的 site-packages 是铁证：依赖解析跟人走)"
else
  bad "PYTHONPATH 指向 venvA 后 venvB 应 import 成功（rc=0）；实际 rc=$crc"
fi

step 6 "PEP 668：绕过 venv 直接装系统层，被 externally-managed-environment 拒绝"
plog="$BUILD/pep668.log"
"$PY" -m pip install --dry-run this-package-does-not-exist-000 >"$plog" 2>&1
prc=$?
grep -E 'externally-managed-environment|To install Python packages' "$plog" | head -4 | sed 's/^/  | /'
if [ "$prc" -ne 0 ] && grep -q 'externally-managed-environment' "$plog"; then
  ok
  echo "  (系统解释器带 EXTERNALLY-MANAGED 标记，pip 直接拒绝——这是防线不是故障；"
  echo "   它存在的意义恰是逼你把包装进 venv，回到 step 3 的正确战场)"
else
  bad "系统层 pip install 应被 PEP 668 拒绝（非零退出 + externally-managed-environment）；实际 rc=$prc"
fi

step 7 "可变默认参数残留判读：call1 的返回值也被第二次调用污染（症状三）"
r1="$(sed -nE 's/^cart call1=(.*)$/\1/p' "$vlog" | head -1)"
r2="$(sed -nE 's/^cart call2=(.*)$/\1/p' "$vlog" | head -1)"
echo "  cart call1=$r1"
echo "  cart call2=$r2"
if grep -q "cart call1=\['apple', 'banana'\]" "$vlog" && grep -q "cart call2=\['apple', 'banana'\]" "$vlog"; then
  ok
  echo "  (两次调用打印同一个列表：默认参数 [] 在 def 时创建一次、所有调用共享，"
  echo "   第二次 append 写进了第一次拿到的那个对象——预测 [apple]/[banana] 的人，见 POE 点)"
else
  bad "cart 两行应同为 ['apple', 'banana']（共享默认对象）；实际 r1=$r1 r2=$r2"
fi

echo
if [ "$pass" -eq 7 ]; then
  echo "RUN-PASS：7/7 判定符合预期"
  exit 0
fi
echo "RUN-FAIL：$pass/7 判定符合预期" >&2
exit 1
