#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-032-do-while-macro"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

#define BAD_ACTION(condition) if (condition) puts("action")
#define SAFE_ACTION(condition) \
    do {                       \
        if (condition) {       \
            puts("action");    \
        }                      \
    } while (0)

int main(void) {
    int outer = 1;
    int inner = 0;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdangling-else"
    if (outer)
        BAD_ACTION(inner);
    else
        puts("broken=outer-else");
#pragma GCC diagnostic pop

    if (outer)
        SAFE_ACTION(inner);
    else
        puts("safe=outer-else");
    puts("safe=done");
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
