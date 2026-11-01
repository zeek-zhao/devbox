#include <stdio.h>

int main(void) {
    printf("float=%.3f\n", 1.2345);
    printf("hex=%08x\n", 42U);
    printf("width=%*d\n", 5, 17);
    return 0;
}
