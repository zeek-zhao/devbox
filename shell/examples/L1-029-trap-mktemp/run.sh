#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-029-trap-mktemp.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK"
