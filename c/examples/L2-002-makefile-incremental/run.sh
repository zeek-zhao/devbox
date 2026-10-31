#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-002-makefile-incremental"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

make -C "$(dirname "$0")" BUILD_DIR="$WORK" all >/dev/null
make -C "$(dirname "$0")" BUILD_DIR="$WORK" all >"$WORK/second-make.log"
if ! grep -q 'Nothing to be done' "$WORK/second-make.log"; then
    echo "incremental: did not report an up-to-date target" >&2
    exit 1
fi
"$WORK/example" >/dev/null
echo "incremental: up-to-date"
