#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-029-setjmp-longjmp"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <setjmp.h>
#include <stdio.h>

static void report_error(jmp_buf target) {
    longjmp(target, 7);
}

int main(void) {
    jmp_buf target;
    volatile int state;
    if ((state = setjmp(target)) == 0) {
        puts("setjmp=0");
        report_error(target);
    }
    printf("after-longjmp=%d\n", state);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
