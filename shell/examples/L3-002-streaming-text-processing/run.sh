#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-002-streaming-text-processing.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
export WORK

bash demo.sh
