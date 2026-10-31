#!/usr/bin/env bash
# ==================================================================
# Python 工具链安装（系统 python3.12 + uv 管理虚拟环境 + 质量工具）
# ==================================================================
set -euo pipefail

: "${PYTHON_VERSION:?需要 PYTHON_VERSION}"
PIP_INDEX_URL="${PIP_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}"

apt-get update
apt-get install -y --no-install-recommends \
  python3 python3-venv python3-dev python3-pip \
  python3-setuptools python3-wheel \
  libffi-dev
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 24.04 的 pip 受 PEP 668 保护，全局装工具必须 --break-system-packages
# uv: 极快的依赖解析（学习用例里作为「现代 Python 工程」的示范）
# ruff: 格式化 + lint 二合一；mypy: 类型检查；pytest: 测试
echo "==> 安装 python 工具链（pip index: ${PIP_INDEX_URL}）"
python3 -m pip install --break-system-packages --no-cache-dir \
  -i "${PIP_INDEX_URL}" \
  uv ruff mypy pytest pytest-cov ipython

echo "==> 自检"
python3 --version
test "$(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')" = "${PYTHON_VERSION}" \
  || { echo "!! Python 版本不是 ${PYTHON_VERSION}" >&2; exit 1; }
uv --version
ruff --version
mypy --version
pytest --version
