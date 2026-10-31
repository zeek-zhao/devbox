#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-024-2d-arrays"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

int main(void) {
    int matrix[3][4] = {{0}};
    int x = 1;
    int y = 2;
    int z = 3;
    int *rows[3] = {&x, &y, &z};
    size_t row_stride = sizeof matrix[0];

    printf("matrix=%zu row=%zu stride=%zu\n", sizeof matrix,
           sizeof matrix[0], row_stride);
    printf("pointer-array=%zu elements=%zu\n", sizeof rows, sizeof rows[0]);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
