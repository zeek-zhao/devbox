#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-031-internal-linkage"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/first.c" <<'EOF'
static int counter;

int next_first(void) {
    return ++counter;
}
EOF

cat > "$TMP/second.c" <<'EOF'
static int counter;

int next_second(void) {
    return ++counter;
}
EOF

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>

int next_first(void);
int next_second(void);

int main(void) {
    printf("first=%d second=%d\n", next_first(), next_second());
    printf("first=%d second=%d\n", next_first(), next_second());
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/first.c" "$TMP/second.c" \
    "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
