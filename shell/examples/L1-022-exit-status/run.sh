#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-022-exit-status.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
