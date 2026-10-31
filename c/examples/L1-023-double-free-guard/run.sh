#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-023-double-free-guard"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int *value = malloc(sizeof *value);
    if (value == NULL) {
        return 1;
    }

    *value = 7;
    printf("value=%d\n", *value);
    free(value);
    value = NULL;
    free(value);
    puts("free(NULL) is safe");
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
