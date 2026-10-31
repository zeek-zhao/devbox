#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$ROOT"
files=(build.sh check-runtime.sh src/main.sh lib/*.sh)
for file in "${files[@]}"; do bash -n "$file"; done
# L2-002-shellcheck-warning-gate
if command -v shellcheck >/dev/null; then
  shellcheck -S warning "${files[@]}"
else
  IMAGE="ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest}"
  docker image inspect "$IMAGE" >/dev/null
  docker run --rm -v "$ROOT:/app:ro" -w /app "$IMAGE" shellcheck -S warning "${files[@]}"
fi
mkdir -p build
printf 'shell build ok\n' >build/build-stamp.txt
printf 'shell build ok\n'
