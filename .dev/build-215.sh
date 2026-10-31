#!/usr/bin/env bash
# 在 215 上构建镜像。用法: build-215.sh "[--only base]" 或 build-215.sh "" 全量
set -euo pipefail

ARGS="${1:---only base}"
echo "==> 215 上构建: scripts/build-images.sh ${ARGS}"
ssh -o BatchMode=yes jenkins@10.22.67.215 "cd ~/devbox && bash scripts/build-images.sh ${ARGS}"
