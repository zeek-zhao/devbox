#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

# Host entry remains offline; all development tools are preinstalled in this image.
if [[ "${1:-}" != "--inside" ]]; then
  exec docker run --rm --pull=never --network none \
    --user "$(id -u):$(id -g)" -e PYTHONDONTWRITEBYTECODE=1 \
    -v "$ROOT:/app" -w /app \
    "ghcr.io/zeek-zhao/devbox-python:${TAG:-latest}" bash /app/build.sh --inside
fi

export PYTHONPATH="$ROOT/src:$ROOT"
mkdir -p build
# Invalidate a previous successful stamp when a new check fails.
rm -f build/build-stamp.txt
ruff check src tests  # L2-005-ruff-check
mypy --strict src  # L2-004-mypy-check
python3 -m pytest -q tests
printf 'python build ok\n' > build/build-stamp.txt
