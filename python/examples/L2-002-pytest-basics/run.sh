#!/usr/bin/env bash
set -euo pipefail

export PYTHONDONTWRITEBYTECODE=1
OUT="${TMPDIR:-/tmp}/devbox-python-L2-002-pytest-basics"
mkdir -p "$OUT"

if ! python3 -m pytest -q -p no:cacheprovider >"$OUT/pytest-check.txt" 2>&1; then
  cat "$OUT/pytest-check.txt" >&2
  exit 1
fi

python3 -m pytest -q -p no:cacheprovider 2>&1 \
  | sed -E 's/ in [0-9.]+s//' \
  | sed -E '/^[[:space:]]*$/d'
