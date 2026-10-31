#!/usr/bin/env bash
set -euo pipefail

export PYTHONDONTWRITEBYTECODE=1
OUT="${TMPDIR:-/tmp}/devbox-python-L2-003-typing-protocols"
mkdir -p "$OUT"

if mypy --no-incremental --cache-dir "${TMPDIR:-/tmp}/devbox-python-L2-003-typing-protocols-mypy" main.py >"$OUT/mypy.txt" 2>&1; then
  echo "protocol type check: passed"
else
  cat "$OUT/mypy.txt" >&2
  exit 1
fi

python3 main.py
