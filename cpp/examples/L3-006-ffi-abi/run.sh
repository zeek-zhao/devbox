#!/usr/bin/env bash
set -euo pipefail

CXX="${CXX:-g++}"
API_OBJ="${TMPDIR:-/tmp}/devbox-cpp-L3-006-ffi-abi-api.o"
OUT="${TMPDIR:-/tmp}/devbox-cpp-L3-006-ffi-abi"

cc -Wall -Wextra -pedantic -c api.c -o "$API_OBJ"
"$CXX" -std=c++20 -Wall -Wextra -pedantic main.cpp "$API_OBJ" -o "$OUT"
"$OUT"
