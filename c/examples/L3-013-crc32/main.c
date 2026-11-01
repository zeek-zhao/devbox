#include <stdint.h>
#include <stdio.h>

static void make_table(uint32_t table[256]) {
    for (uint32_t i = 0U; i < 256U; ++i) {
        uint32_t value = i;
        for (unsigned int bit = 0U; bit < 8U; ++bit) {
            value = (value & 1U) != 0U ? (value >> 1U) ^ UINT32_C(0xedb88320) : value >> 1U;
        }
        table[i] = value;
    }
}

int main(void) {
    uint32_t table[256];
    make_table(table);
    uint32_t crc = UINT32_C(0xffffffff);
    const unsigned char* text = (const unsigned char*)"123456789";
    for (size_t i = 0; text[i] != '\0'; ++i) {
        const uint32_t index = (crc ^ text[i]) & UINT32_C(0xff);
        crc = table[index] ^ (crc >> 8U);
    }
    crc ^= UINT32_C(0xffffffff);
    printf("crc32=0x%08x\n", crc);
    return crc == UINT32_C(0xcbf43926) ? 0 : 1;
}
