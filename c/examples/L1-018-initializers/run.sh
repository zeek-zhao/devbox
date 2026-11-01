#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-018-initializers"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

struct point {
    int x;
    int y;
};

int main(void) {
    struct point p = {.y = 2, .x = 1};
    printf("x=%d y=%d\n", p.x, p.y);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
