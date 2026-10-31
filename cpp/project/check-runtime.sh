#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$ROOT/build/devbox-cpp-project"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"

if [[ ! -x "$BINARY" ]]; then
  echo "[fail] 未找到 $BINARY；请先在 cpp/project/ 中构建项目" >&2
  exit 1
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[skip] devbox-runtime 镜像不在本地，先 docker pull"
  exit 0
fi

INPUT="$(mktemp)"
trap 'rm -f "$INPUT"' EXIT
printf 'alpha beta\ngamma alpha\ndelta\n' >"$INPUT"

ACTUAL="$(docker run --rm \
  -v "$BINARY:/devbox-cpp-project:ro" \
  -v "$INPUT:/tmp/runtime-check.txt:ro" \
  "$IMAGE" /devbox-cpp-project /tmp/runtime-check.txt alpha)"
EXPECTED=$'1: alpha beta\n2: gamma alpha'

if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  printf '[fail] runtime 输出不匹配\n期望:\n%s\n实际:\n%s\n' "$EXPECTED" "$ACTUAL" >&2
  exit 1
fi

echo "[pass] devbox-runtime 查询输出正确"
