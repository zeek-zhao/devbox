#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-012-null-delimited-paths.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK/files"
