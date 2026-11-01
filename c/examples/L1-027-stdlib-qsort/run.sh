#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-027-stdlib-qsort"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

struct item {
    int id;
    int score;
};

static int compare_score(const void *left, const void *right) {
    const struct item *a = left;
    const struct item *b = right;
    return (a->score > b->score) - (a->score < b->score);
}

int main(void) {
    struct item items[] = {{1, 30}, {2, 10}, {3, 20}};
    const size_t count = sizeof items / sizeof items[0];
    qsort(items, count, sizeof items[0], compare_score);
    for (size_t i = 0; i < count; ++i) {
        printf("%d:%d%s", items[i].id, items[i].score,
               i + 1 == count ? "\n" : " ");
    }
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
