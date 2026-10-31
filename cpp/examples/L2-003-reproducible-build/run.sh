#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-003-reproducible-build"
mkdir -p "$BUILD/first" "$BUILD/second"

"$CXX" -std=c++20 -Wall -Wextra -pedantic "-ffile-prefix-map=$PWD=." "$PWD/main.cpp" -o "$BUILD/first/program"
"$CXX" -std=c++20 -Wall -Wextra -pedantic "-ffile-prefix-map=$PWD=." "$PWD/main.cpp" -o "$BUILD/second/program"

"$BUILD/first/program" >"$BUILD/first/output.txt"
"$BUILD/second/program" >"$BUILD/second/output.txt"
cmp -s "$BUILD/first/output.txt" "$BUILD/second/output.txt"
cmp -s "$BUILD/first/program" "$BUILD/second/program"

HASH_FIRST="$(sha256sum "$BUILD/first/program" | cut -d ' ' -f 1)"
HASH_SECOND="$(sha256sum "$BUILD/second/program" | cut -d ' ' -f 1)"
test "$HASH_FIRST" = "$HASH_SECOND"

cat "$BUILD/first/output.txt"
printf 'identical: yes\n'
printf 'sha256 first: %.12s\n' "$HASH_FIRST"
printf 'sha256 second: %.12s\n' "$HASH_SECOND"
