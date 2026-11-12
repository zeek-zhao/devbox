#!/usr/bin/env bash
# T-001-venv-mix-mutable-default 最小复现：搭 venvA/venvB 两个环境，把占位包 myproj
# 只放进 venvA 的 site-packages，再用 venvB 的解释器跑 main.py ——
# 稳定触发一次 ModuleNotFoundError（素材 S-13）。
# 按 docs/72 §2 样板约定：复现成功 = 故障被触发 = 本脚本以非零退出码结束。
# 产物只写临时目录，不入库。用法：bash repro.sh
set -uo pipefail
cd "$(dirname "$0")" || exit

PY="${PY:-python3}"
BUILD="${TMPDIR:-/tmp}/devbox-python-T-001-venv-mix-mutable-default"
VENV_A="$BUILD/venvA"
VENV_B="$BUILD/venvB"
mkdir -p "$BUILD"

if [ ! -x "$VENV_A/bin/python" ]; then
  "$PY" -m venv "$VENV_A" || {
    echo "repro: venvA 创建失败" >&2
    exit 2
  }
fi
if [ ! -x "$VENV_B/bin/python" ]; then
  "$PY" -m venv "$VENV_B" || {
    echo "repro: venvB 创建失败" >&2
    exit 2
  }
fi

# 占位第三方包 myproj：只进 venvA 的 site-packages（真实安装动作的离线替身，输出稳定）。
sp_a="$(ls -d "$VENV_A"/lib/python3*/site-packages 2>/dev/null | head -1)"
[ -n "$sp_a" ] || {
  echo "repro: 未找到 venvA site-packages（镜像漂移，停止交维护者）" >&2
  exit 2
}
cat >"$BUILD/myproj.py" <<'PYEOF'
"""myproj · 本 lab 的占位第三方包，只存在于 venvA 的 site-packages。"""

VERSION = "1.0.0-venvA"
PYEOF
cp "$BUILD/myproj.py" "$sp_a/myproj.py" || {
  echo "repro: myproj 入位失败" >&2
  exit 2
}

# 触发：venvB 的解释器跑带缺陷的 main.py —— import myproj 必报 ModuleNotFoundError。
"$VENV_B/bin/python" main.py 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then
  echo "repro: venvB 竟然 import 成功（环境异常：怀疑 PYTHONPATH 串味通道已存在，见 WALKTHROUGH 决策树 Q3）" >&2
  exit 3
fi
exit "$rc"
