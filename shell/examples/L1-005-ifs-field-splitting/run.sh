#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L1-005-ifs-field-splitting.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh
