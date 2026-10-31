#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-007-cross-compilation"
GOOS=linux GOARCH=arm64 go build -o "$OUT" .
file -b "$OUT" | grep -q 'ARM aarch64'
printf 'cross build: linux/arm64\n'
