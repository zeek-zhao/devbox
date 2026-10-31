#!/usr/bin/env bash
set -euo pipefail

export PYTHONDONTWRITEBYTECODE=1
OUT="${TMPDIR:-/tmp}/devbox-python-L2-005-ruff-check"
mkdir -p "$OUT"

if ruff check --no-cache . >"$OUT/clean.txt" 2>&1; then
  echo "example directory: passed"
else
  cat "$OUT/clean.txt" >&2
  exit 1
fi

printf 'import os\n' >"$OUT/ruff_violation.py"
if ruff check --no-cache "$OUT/ruff_violation.py" >"$OUT/violation.txt" 2>&1; then
  echo "known violation: unexpectedly accepted" >&2
  exit 1
else
  echo "known violation: rejected"
fi
