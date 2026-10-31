#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
BUILD="${TMPDIR:-/tmp}/devbox-cpp-L2-001-multifile-odr-build"
mkdir -p "$BUILD"

"$CXX" -std=c++20 -Wall -Wextra -pedantic -I. main.cpp alpha.cpp beta.cpp -o "$BUILD/multifile-odr"
"$BUILD/multifile-odr"
