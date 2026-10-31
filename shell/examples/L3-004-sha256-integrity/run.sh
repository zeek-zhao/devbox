#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-004-sha256-integrity.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export WORK

bash demo.sh
