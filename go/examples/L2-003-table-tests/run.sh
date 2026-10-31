#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-003-table-tests"
mkdir -p "$OUT"
go build -o "$OUT/program" .
go test -v -count=1 ./... 2>&1 \
  | sed -E 's/\([0-9.]+s\)//g; s/finished in [0-9.]+s//' \
  | sed -E 's/[[:space:]]+$//; /^[[:space:]]*$/d; /^ok[[:space:]].*$/d'
