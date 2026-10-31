#!/usr/bin/env bash
set -euo pipefail

if cat "$1" >"$2"; then
  printf '%s\n' 'config: loaded'
else
  printf '%s\n' 'operation failed: read-config' >&2
  exit 1
fi
