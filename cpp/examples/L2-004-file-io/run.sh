#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-004-file-io"
mkdir -p "$BUILD"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp -o "$BUILD/file-io"
"$BUILD/file-io" "$BUILD/data"
