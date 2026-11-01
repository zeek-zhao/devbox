#!/usr/bin/env bash
set -euo pipefail

CC="${CC:-gcc}"
TMP="${TMPDIR:-/tmp}/devbox-L1-034-include-guard"
rm -rf "$TMP"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/a.h" <<'EOF'
#ifndef EXAMPLE_A_H
#define EXAMPLE_A_H

struct item {
    int value;
};

#include "middle.h"

#endif
EOF

cat > "$TMP/middle.h" <<'EOF'
#ifndef EXAMPLE_MIDDLE_H
#define EXAMPLE_MIDDLE_H

#include "b.h"

#endif
EOF

cat > "$TMP/b.h" <<'EOF'
#ifndef EXAMPLE_B_H
#define EXAMPLE_B_H

#include "a.h"

#endif
EOF

cat > "$TMP/main.c" <<'EOF'
#include <stdio.h>
#include "a.h"
#include "b.h"

int main(void) {
    struct item value = {.value = 5};
    printf("value=%d\n", value.value);
    return 0;
}
EOF

"$CC" -std=c17 -O2 -Wall -Wextra -Werror -I"$TMP" "$TMP/main.c" -o "$TMP/main"
"$TMP/main"
