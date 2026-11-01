#include <stdint.h>
#include <stdio.h>

typedef union word_bytes {
    uint32_t word;
    unsigned char bytes[sizeof(uint32_t)];
} word_bytes;

static uint32_t swap_bytes(uint32_t value) {
    return ((value & UINT32_C(0x000000ff)) << 24U) | ((value & UINT32_C(0x0000ff00)) << 8U) |
           ((value & UINT32_C(0x00ff0000)) >> 8U) | ((value & UINT32_C(0xff000000)) >> 24U);
}

int main(void) {
    const word_bytes sample = {UINT32_C(1)};
    const char* endian = sample.bytes[0] == 1U ? "little" : "big";
    printf("host_endian=%s\n", endian);
    printf("byte_swap=0x%08x\n", swap_bytes(UINT32_C(0x12345678)));
    return 0;
}
