#include <stdint.h>
#include <stdio.h>

int main(void) {
    union Word {
        uint32_t u;
        uint8_t b[4];
    } word = {.u = UINT32_C(0x01020304)};

    printf("bytes=%02X %02X %02X %02X\n", (unsigned int)word.b[0], (unsigned int)word.b[1],
           (unsigned int)word.b[2], (unsigned int)word.b[3]);
    return 0;
}
