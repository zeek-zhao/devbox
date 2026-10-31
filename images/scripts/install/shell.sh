#!/usr/bin/env bash
# ==================================================================
# Shell 工具链安装（bash 5.2 自带 + bats 测试框架 + 静态检查）
# 注意：shellcheck / shfmt 已在 tool 层装过，这里重复装是幂等的，
#       目的是让 shell 镜像脱离 tool 层也能独立使用。
# ==================================================================
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bats \
  shellcheck \
  shfmt \
  bash-completion \
  bc time getopt \
  coreutils findutils grep sed gawk \
  curl jq
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

echo "==> 自检"
bash --version | head -1
bats --version
shellcheck --version | grep -E '^version:'
shfmt --version
# 严格模式自检：这是 shell 用例的第一课，镜像自己先做到
bash -c 'set -euo pipefail; echo "strict mode OK"'
