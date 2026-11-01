#include <stdio.h>

struct PoorlyOrdered {
    char first;
    int number;
    char last;
};

struct BetterOrdered {
    int number;
    char first;
    char last;
};

int main(void) {
    printf("char-int-char=%zu\n", sizeof(struct PoorlyOrdered));
    printf("int-char-char=%zu\n", sizeof(struct BetterOrdered));
    return 0;
}
