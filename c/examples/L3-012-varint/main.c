#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

static size_t encode(uint32_t value, unsigned char output[5]) {
    size_t length = 0U;
    do {
        unsigned char byte = (unsigned char)(value & UINT32_C(0x7f));
        value >>= 7U;
        if (value != 0U) {
            byte |= 0x80U;
        }
        output[length++] = byte;
    } while (value != 0U);
    return length;
}

static bool decode(const unsigned char* input, size_t length, uint32_t* value) {
    uint32_t result = 0U;
    for (size_t i = 0; i < length && i < 5U; ++i) {
        const unsigned int shift = (unsigned int)(i * 7U);
        if (i == 4U && (input[i] & 0xf0U) != 0U) {
            return false;
        }
        result |= (uint32_t)(input[i] & 0x7fU) << shift;
        if ((input[i] & 0x80U) == 0U) {
            if (i + 1U != length) {
                return false;
            }
            *value = result;
            return true;
        }
    }
    return false;
}

int main(void) {
    unsigned char bytes[5];
    const size_t length = encode(300U, bytes);
    uint32_t decoded = 0U;
    if (!decode(bytes, length, &decoded)) {
        return 1;
    }
    printf("encoded=");
    for (size_t i = 0; i < length; ++i) {
        printf("%s%02X", i == 0U ? "" : " ", bytes[i]);
    }
    printf("\ndecoded=%u\n", decoded);
    return decoded == 300U ? 0 : 1;
}
