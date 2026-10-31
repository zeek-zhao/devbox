#!/usr/bin/env bash
# ==================================================================
# Vue 3 工具链安装（Node 官方二进制 + 全局安装 vue 三件套 + prettier）
# ------------------------------------------------------------------
# 为什么不用 apt 的 nodejs：24.04 源里是 18.19，够用但版本偏旧，
# 而且 apt 的 npm 装全局包会踩 EACCES（要 sudo 或改 prefix），
# 官方 tarball 解到 /usr/local 之后 npm 前缀本来就是可写的，省掉这些坑。
#
# 为什么不用 nvm：nvm 是给交互式开发用的，装它要 source 一个 shell 函数，
# 在 Dockerfile 的 RUN 里不生效；而且它把 node 放在用户目录下，
# 换个用户（CI 容器常以非 root 跑）就找不到。
#
# 为什么不用 vite：产物文件名带内容 hash，expected.txt 没法固定。
# 本镜像的用例走 SFC + SSR，输出是确定的 HTML 字符串。
# ==================================================================
set -euo pipefail

: "${NODE_VERSION:?需要 NODE_VERSION}"
: "${NODE_SHA256:?需要 NODE_SHA256}"
: "${VUE_VERSION:?需要 VUE_VERSION}"
: "${PRETTIER_VERSION:?需要 PRETTIER_VERSION}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"

# 只锁了 x86_64 的校验和（CI runner 与 215 都是 x86_64）。
# 换 arm64 必须补对应校验和，这里直接报错而不是静默跳过。
case "$(uname -m)" in
  x86_64) NODE_ARCH="x64" ;;
  *)
    echo "!! Node 只锁了 x64 的校验和，当前架构 $(uname -m) 没有对应校验和" >&2
    exit 1
    ;;
esac

echo "==> 安装 Node ${NODE_VERSION}"
curl -fsSL --retry 3 --retry-delay 2 \
  -o /tmp/node.tar.xz \
  "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"

echo "${NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c -

# --strip-components=1 把 node-vX-linux-x64/ 这层壳去掉，
# 直接铺到 /usr/local 下（bin/ lib/ include/ share/），与系统布局一致。
tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1
rm -f /tmp/node.tar.xz

node --version
npm --version

# 构建期走镜像源加速；运行期不需要网络，所以这只是构建期优化
npm config set registry "$NPM_REGISTRY" --global

echo "==> 安装 vue ${VUE_VERSION} 三件套 + prettier ${PRETTIER_VERSION}"
# vue                  运行时（CJS 构建自带模板编译器）
# @vue/compiler-sfc    编译 .vue 单文件组件
# @vue/server-renderer SSR 的 renderToString
# prettier             格式化（.vue / .js）
npm install --global --no-audit --no-fund \
  "vue@${VUE_VERSION}" \
  "@vue/compiler-sfc@${VUE_VERSION}" \
  "@vue/server-renderer@${VUE_VERSION}" \
  "prettier@${PRETTIER_VERSION}"

# npm 缓存留在镜像里纯属浪费体积
npm cache clean --force 2>/dev/null || true

echo "==> 自检"
node --version
npm --version
prettier --version
# NODE_PATH 由 Dockerfile 的 ENV 提供，这里显式传一遍，
# 保证「镜像能装」和「运行期能 require」是同一件事
NODE_PATH=/usr/local/lib/node_modules node -e '
  const { createSSRApp } = require("vue");
  const { renderToString } = require("@vue/server-renderer");
  const { parse } = require("@vue/compiler-sfc");
  const app = createSSRApp({ template: "<p>hello {{ who }}</p>", data: () => ({ who: "devbox" }) });
  renderToString(app).then((html) => {
    if (html !== "<p>hello devbox</p>") {
      console.error("SSR 输出不符合预期: " + html);
      process.exit(1);
    }
    console.log("ssr:", html);
    console.log("compiler-sfc:", typeof parse === "function" ? "ok" : "missing");
  });
'
