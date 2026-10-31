#!/usr/bin/env bash
set -euo pipefail

export PYTHONDONTWRITEBYTECODE=1
OUT="${TMPDIR:-/tmp}/devbox-python-L2-004-mypy-check"
mkdir -p "$OUT"

if mypy --no-incremental --cache-dir "${TMPDIR:-/tmp}/devbox-python-L2-004-mypy-check-mypy" valid.py >"$OUT/valid.txt" 2>&1; then
  echo "valid call: passed"
else
  cat "$OUT/valid.txt" >&2
  exit 1
fi

if mypy --no-incremental --cache-dir "${TMPDIR:-/tmp}/devbox-python-L2-004-mypy-check-mypy" invalid.py >"$OUT/invalid.txt" 2>&1; then
  echo "incompatible call: unexpectedly accepted" >&2
  exit 1
else
  echo "incompatible call: rejected"
fi
