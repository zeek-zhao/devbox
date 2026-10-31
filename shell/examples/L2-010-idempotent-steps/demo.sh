#!/usr/bin/env bash
set -euo pipefail

target="$1"
if [ ! -f "$target" ] || ! grep -Fxq 'managed=ready' "$target"; then
  printf '%s\n' 'managed=ready' >"$target.tmp"
  mv "$target.tmp" "$target"
fi
