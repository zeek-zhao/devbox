#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-002-variable-expansion.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
