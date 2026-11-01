#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-L2-010-strict-warnings"
rm -rf "$WORK"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

if gcc -std=c17 -Wall -Wextra -Wconversion -Wshadow -Wcast-qual -Werror main.c -o "$WORK/example" 2>"$WORK/compiler.log"; then
    echo "strict warnings: compilation unexpectedly succeeded" >&2
    exit 1
fi
for warning in conversion shadows qualifier; do
    if ! grep -qi "$warning" "$WORK/compiler.log"; then
        echo "strict warnings: missing $warning diagnostic" >&2
        exit 1
    fi
done
echo "strict warnings: conversion, shadow, and cast-qual detected"
