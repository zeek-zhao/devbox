#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-023-functions-local-return.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
