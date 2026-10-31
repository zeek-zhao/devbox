#include <limits.h>
#include <stdio.h>

int main(void) {
    unsigned int wrapped = UINT_MAX + 1u;

    printf("UINT_MAX=%u\n", UINT_MAX);
    printf("UINT_MAX + 1u = %u\n", wrapped);
    return 0;
}
