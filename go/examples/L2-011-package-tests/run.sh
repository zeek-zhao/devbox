#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-011-package-tests"
mkdir -p "$OUT"
go test ./... >"$OUT/tests.log"
printf 'module tests: passed\n'
if (cd external && go build -o "$OUT/external" . >"$OUT/internal-boundary.log" 2>&1); then
  echo "internal boundary: unexpectedly allowed"
  exit 1
else
  grep -q 'use of internal package' "$OUT/internal-boundary.log"
  printf 'internal boundary: rejected\n'
fi
go build -o "$OUT/program" .
"$OUT/program"
