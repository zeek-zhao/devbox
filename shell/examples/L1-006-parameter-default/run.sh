#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-006-parameter-default.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
