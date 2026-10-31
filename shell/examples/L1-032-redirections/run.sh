#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-032-redirections.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK"
