#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-028-bsearch"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

static int compare_ints(const void *left, const void *right) {
    int a = *(const int *)left;
    int b = *(const int *)right;
    return (a > b) - (a < b);
}

int main(void) {
    int values[] = {9, 2, 7, 4, 1};
    const size_t count = sizeof values / sizeof values[0];
    qsort(values, count, sizeof values[0], compare_ints);

    int hit_key = 7;
    int miss_key = 6;
    int *hit = bsearch(&hit_key, values, count, sizeof values[0], compare_ints);
    int *miss = bsearch(&miss_key, values, count, sizeof values[0], compare_ints);
    printf("hit=%d\n", hit == NULL ? 0 : *hit);
    printf("miss=%s\n", miss == NULL ? "not found" : "found");
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
