#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$ROOT/build/devbox-rust-project"
IMAGE="ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest}"

if [[ ! -x "$BINARY" ]]; then
  bash "$ROOT/build.sh"
fi

if docker image inspect "$IMAGE" >/dev/null; then
  :
else
  echo "[skip] devbox-runtime 不在本地"
  exit 0
fi

ACTUAL="$(docker run --rm \
  -v "$BINARY:/app:ro" \
  "$IMAGE" /app --self-check)"
EXPECTED=$'count:\nalpha: 2\nbeta: 1\ngamma: 1\nrepeat: 2\ndupe:\nrepeat\nbench:\noperations: 1000'

if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  printf '[fail] runtime 输出不匹配\n期望:\n%s\n实际:\n%s\n' "$EXPECTED" "$ACTUAL" >&2
  exit 1
fi

echo "[pass] rust runtime OK"
