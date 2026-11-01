#include <stdio.h>

enum Color { RED = 2, GREEN, BLUE = 7, WHITE };

int main(void) {
    printf("RED=%d GREEN=%d BLUE=%d WHITE=%d\n", RED, GREEN, BLUE, WHITE);
    return 0;
}
