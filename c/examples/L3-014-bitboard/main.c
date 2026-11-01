#include <stdint.h>
#include <stdio.h>

enum { ELEMENTS = 200, WORDS = (ELEMENTS + 63) / 64 };

static void set_bit(uint64_t bits[WORDS], size_t index) {
    bits[index / 64U] |= UINT64_C(1) << (index % 64U);
}

int main(void) {
    uint64_t bits[WORDS] = {0U};
    const size_t selected[] = {1U, 64U, 130U, 199U};
    for (size_t i = 0; i < sizeof(selected) / sizeof(selected[0]); ++i) {
        set_bit(bits, selected[i]);
    }
    for (size_t i = 0; i < WORDS; ++i) {
        printf("word[%zu]=0x%016llx\n", i, (unsigned long long)bits[i]);
    }
    return 0;
}
