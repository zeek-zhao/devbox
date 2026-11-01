#include <stdio.h>

struct Flags {
    unsigned int a : 3;
    unsigned int b : 5;
};

int main(void) {
    struct Flags flags = {0};
    volatile unsigned int wide_a = 13;
    volatile unsigned int wide_b = 42;

    flags.a = wide_a;
    flags.b = wide_b;
    printf("a(3 bits)=%u\n", (unsigned int)flags.a);
    printf("b(5 bits)=%u\n", (unsigned int)flags.b);
    return 0;
}
