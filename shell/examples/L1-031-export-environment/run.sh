#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-031-export-environment.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK"
