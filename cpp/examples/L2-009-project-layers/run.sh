#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L2-009-project-layers"

"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp command.cpp index.cpp storage.cpp -o "$OUT"
"$OUT"
