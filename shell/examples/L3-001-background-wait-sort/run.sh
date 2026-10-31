#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-001-background-wait-sort.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export WORK

bash demo.sh
