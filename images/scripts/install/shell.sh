#!/usr/bin/env bash
# ==================================================================
# Shell 工具链安装（bash 5.2 自带 + bats 测试框架 + 静态检查）
# 注意：shellcheck / shfmt 已在 tool 层装过，这里重复装是幂等的，
#       目的是让 shell 镜像脱离 tool 层也能独立使用。
# ==================================================================
set -euo pipefail

: "${YQ_VERSION:?需要 YQ_VERSION}"
: "${YQ_SHA256:?需要 YQ_SHA256}"

apt-get update
# 注意：Ubuntu 24.04 里没有独立的 getopt 包（已被拆进 util-linux-extra），
# 写 getopt 会直接 `E: Unable to locate package` 让整层构建失败。
apt-get install -y --no-install-recommends \
  bats \
  shellcheck \
  shfmt \
  bash-completion \
  bc time util-linux-extra \
  coreutils findutils grep sed gawk \
  curl jq
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------
# yq：YAML 的 jq。apt 源里没有，只能下 GitHub release 的单文件二进制。
# 之所以必须有它：shared/lib/yaml.sh 的全部函数都建立在 yq 之上，
# 镜像里没有 yq 等于那个库是死的。
# 校验和来自 images/versions.env（与 Go 工具链同一套规矩）。
# ------------------------------------------------------------------
case "$(uname -m)" in
  x86_64) YQ_ARCH="amd64" ;;
  *)
    echo "!! yq 只锁了 amd64 的校验和，当前架构 $(uname -m) 没有对应校验和" >&2
    exit 1
    ;;
esac

echo "==> 安装 yq ${YQ_VERSION}"
curl -fsSL --retry 3 --retry-delay 2 \
  -o /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH}"

echo "${YQ_SHA256}  /usr/local/bin/yq" | sha256sum -c -
chmod +x /usr/local/bin/yq

echo "==> 自检"
bash --version | head -1
bats --version
shellcheck --version | grep -E '^version:'
shfmt --version
yq --version
# 严格模式自检：这是 shell 用例的第一课，镜像自己先做到
bash -c 'set -euo pipefail; echo "strict mode OK"'
