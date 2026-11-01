# ==================================================================
# L2  vue —— Vue 3 语言镜像  (FROM tool，与其他语言镜像横向并列)
# ------------------------------------------------------------------
# 取舍：**不装 vite**。vite 的产物文件名带内容 hash，expected.txt 没法固定，
# 用例就没法做逐行精确比对。这里走 SFC + SSR 渲染：
#   @vue/compiler-sfc 编译单文件组件 -> @vue/server-renderer 的 renderToString
#   输出是确定的 HTML 字符串，可以直接比。
#
# 依赖包用 npm 全局安装（构建期联网），运行期不需要网络。
# NODE_PATH 让 require('vue') 能找到全局模块 —— 注意只对 CommonJS 生效，
# 所以用例统一用 require 而不是 import。
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG NODE_VERSION=22.11.0
ARG NODE_SHA256=83bf07dd343002a26211cf1fcd46a9d9534219aad42ee02847816940bf610a72
ARG VUE_VERSION=3.5.44
ARG PRETTIER_VERSION=3.9.10
ARG NPM_REGISTRY=https://registry.npmmirror.com

LABEL org.opencontainers.image.title="devbox-vue" \
      devbox.layer="lang" \
      devbox.language="vue"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/vue.sh

# 全局 node_modules 不在 Node 的默认解析路径里，必须显式指过去
ENV NODE_PATH=/usr/local/lib/node_modules \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

WORKDIR /work/vue
