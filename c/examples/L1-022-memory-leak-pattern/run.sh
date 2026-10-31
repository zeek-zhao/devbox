#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-022-memory-leak-pattern"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int status = 1;
    int *first = NULL;
    int *second = NULL;

    first = malloc(sizeof *first);
    if (first == NULL) {
        goto cleanup;
    }
    second = malloc(sizeof *second);
    if (second == NULL) {
        goto cleanup;
    }

    *first = 20;
    *second = 22;
    printf("sum=%d\n", *first + *second);
    status = 0;

cleanup:
    free(second);
    free(first);
    return status;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
