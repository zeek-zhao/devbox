#!/usr/bin/env bash
# ==================================================================
# Go 工具链安装（官方 tarball，不依赖 Ubuntu apt 的旧版本）
# ==================================================================
set -euo pipefail

: "${GO_VERSION:?需要 GO_VERSION}"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) goarch=amd64 ;;
  arm64) goarch=arm64 ;;
  *) echo "不支持的架构: $arch" >&2; exit 1 ;;
esac

url="https://go.dev/dl/go${GO_VERSION}.linux-${goarch}.tar.gz"
echo "==> 下载 Go ${GO_VERSION} (${goarch})"
# go.dev 有 302 跳到 dl.google.com，-L 必须带
curl -fsSL --retry 3 --retry-delay 2 -o /tmp/go.tgz "$url"

if [ -n "${GO_SHA256:-}" ]; then
  echo "${GO_SHA256}  /tmp/go.tgz" | sha256sum -c -
  echo "==> SHA256 校验通过"
else
  echo "!! 未提供 GO_SHA256，跳过校验（versions.env 里补上更安全）"
fi

rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tgz
rm -f /tmp/go.tgz

# 只开放 Go 模块与构建缓存；不让任意用户替换 /go/bin 下的工具。
mkdir -p /go/bin /go/pkg /go/cache
chmod -R a+rwX /go/pkg /go/cache

echo "==> 自检"
/usr/local/go/bin/go version
