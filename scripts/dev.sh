#!/usr/bin/env bash
# ==================================================================
# 进入学习容器（日常用得最多的命令）
# ------------------------------------------------------------------
# 用法：
#   scripts/dev.sh cpp                     # 交互式进 cpp 容器，cwd=/work/cpp
#   scripts/dev.sh all                     # 进总环境（8G 那个，切语言用）
#   scripts/dev.sh rust cargo test         # 在容器里跑一条命令
#   scripts/dev.sh go bash -lc 'go test ./...'
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${TAG:-local}"
REGISTRY="${REGISTRY:-$(grep -E '^REGISTRY=' images/versions.env 2>/dev/null | cut -d= -f2 || true)}"
PREFIX="${REGISTRY:+${REGISTRY}/}"

LANG_ARG="${1:-}"; shift || true
if [ -z "$LANG_ARG" ]; then
  echo "用法: scripts/dev.sh <cpp|go|rust|shell|python|java|all> [命令...]" >&2
  exit 2
fi

case "$LANG_ARG" in
  cpp|go|rust|shell|python|java|all) ;;
  *) echo "未知语言: $LANG_ARG" >&2; exit 2 ;;
esac

IMAGE="${PREFIX}devbox-${LANG_ARG}:${TAG}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "镜像不存在: $IMAGE" >&2
  echo "先在 215 上跑 scripts/build-images.sh，或等 CI 构建完 docker pull" >&2
  exit 1
fi

host_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else echo "$1"; fi
}

WORKDIR="/work/${LANG_ARG}"
[ "$LANG_ARG" = "all" ] && WORKDIR="/work"

# 常用端口：后面 java/go 的 web 项目要用
PORTS=(-p 8080:8080 -p 9090:9090 -p 5000:5000)

if [ $# -gt 0 ]; then
  exec docker run --rm -i \
    -v "$(host_path "$ROOT"):/work" \
    -w "$WORKDIR" \
    "${PORTS[@]}" \
    -e "TERM=${TERM:-xterm-256color}" \
    "$IMAGE" "$@"
else
  exec docker run --rm -it \
    -v "$(host_path "$ROOT"):/work" \
    -w "$WORKDIR" \
    "${PORTS[@]}" \
    -e "TERM=${TERM:-xterm-256color}" \
    "$IMAGE" zsh
fi
