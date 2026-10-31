#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-007-posix-bash-portability.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

sh posix-demo.sh
bash bash-demo.sh
