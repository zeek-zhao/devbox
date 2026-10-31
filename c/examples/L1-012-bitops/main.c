#include <limits.h>
#include <stdio.h>

#define SET_BIT(value, bit) ((value) |= (1u << (bit)))
#define CLR_BIT(value, bit) ((value) &= ~(1u << (bit)))
#define TGL_BIT(value, bit) ((value) ^= (1u << (bit)))
#define TST_BIT(value, bit) (((value) >> (bit)) & 1u)

int main(void) {
    unsigned int flags = 0;
    const unsigned int bit_count = sizeof(flags) * CHAR_BIT;

    if (bit_count <= 5u) {
        return 1;
    }
    SET_BIT(flags, 2u);
    printf("set bit 2: 0x%08X\n", flags);
    SET_BIT(flags, 5u);
    printf("set bit 5: 0x%08X\n", flags);
    printf("test bit 5: %u\n", TST_BIT(flags, 5u));
    CLR_BIT(flags, 2u);
    printf("clear bit 2: 0x%08X\n", flags);
    TGL_BIT(flags, 5u);
    printf("toggle bit 5: 0x%08X\n", flags);
    return 0;
}
