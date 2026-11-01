#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-030-static-local"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

static int next_value(void) {
    static int value = 0;
    return ++value;
}

int main(void) {
    printf("%d\n", next_value());
    printf("%d\n", next_value());
    printf("%d\n", next_value());
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
