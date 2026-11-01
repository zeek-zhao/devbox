#!/usr/bin/env bash
# 用例 hello —— 验证 Vue 镜像能 require 到 vue 三件套并做 SSR 渲染
#
# NODE_PATH 由镜像的 ENV 提供（/usr/local/lib/node_modules），
# 所以这里不需要额外设什么，直接 node 就行。
set -euo pipefail

node hello.js
