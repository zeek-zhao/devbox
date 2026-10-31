#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-020-malloc-free"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    const size_t count = 5;
    int *values = malloc(count * sizeof *values);
    if (values == NULL) {
        return 1;
    }

    int sum = 0;
    for (size_t i = 0; i < count; ++i) {
        values[i] = (int)i + 1;
        sum += values[i];
    }
    printf("sum=%d\n", sum);
    free(values);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
