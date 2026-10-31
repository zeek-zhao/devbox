#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-021-calloc-realloc"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *values = calloc(3, sizeof *values);
    if (values == NULL) {
        return 1;
    }
    printf("calloc sum=%d\n", values[0] + values[1] + values[2]);
    values[0] = 1;
    values[1] = 2;
    values[2] = 3;

    volatile size_t impossible_size = SIZE_MAX;
    int *resized = realloc(values, impossible_size);
    if (resized != NULL) {
        free(resized);
        return 2;
    }

    printf("realloc failed; original sum=%d\n",
           values[0] + values[1] + values[2]);
    free(values);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
