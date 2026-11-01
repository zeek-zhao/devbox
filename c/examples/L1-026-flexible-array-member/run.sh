#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-026-flexible-array-member"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct buf {
    size_t n;
    char data[];
};

int main(void) {
    const char text[] = "hello";
    const size_t length = sizeof text - 1;
    struct buf *buffer = malloc(sizeof *buffer + length + 1);
    if (buffer == NULL) {
        return 1;
    }

    buffer->n = length;
    memcpy(buffer->data, text, length + 1);
    printf("n=%zu data=%s\n", buffer->n, buffer->data);
    free(buffer);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
