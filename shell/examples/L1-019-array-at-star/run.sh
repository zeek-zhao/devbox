#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-019-array-at-star.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
