#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-033-macro-stringify"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

#define VALUE 42
#define PRE pre
#define FIX fix
#define STR(value) #value
#define XSTR(value) STR(value)
#define CAT(left, right) left##right
#define XCAT(left, right) CAT(left, right)

int prefix = 7;

int main(void) {
    printf("STR=%s\n", STR(VALUE));
    printf("XSTR=%s\n", XSTR(VALUE));
    printf("CAT=%s\n", XSTR(CAT(pre, fix)));
    printf("XCAT=%d\n", XCAT(PRE, FIX));
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
