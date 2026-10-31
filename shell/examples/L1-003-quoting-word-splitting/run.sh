#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-003-quoting-word-splitting.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK"
