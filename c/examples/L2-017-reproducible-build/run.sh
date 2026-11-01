#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-017-reproducible-build"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

gcc -std=c17 -Wall -Wextra -Werror -g "-ffile-prefix-map=$PWD=." main.c -o "$WORK/first"
gcc -std=c17 -Wall -Wextra -Werror -g "-ffile-prefix-map=$PWD=." main.c -o "$WORK/second"
if ! cmp -s "$WORK/first" "$WORK/second"; then
    echo "builds: binary mismatch" >&2
    exit 1
fi
"$WORK/first" >/dev/null
echo "builds: reproducible"
