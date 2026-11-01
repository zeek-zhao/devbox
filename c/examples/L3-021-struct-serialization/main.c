#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

typedef struct record_v1 {
    uint16_t id;
    int32_t score;
} record_v1;

typedef struct record_v2 {
    uint16_t id;
    int32_t score;
    bool enabled;
} record_v2;

static void put_u16(unsigned char* output, uint16_t value) {
    output[0] = (unsigned char)(value >> 8U);
    output[1] = (unsigned char)value;
}

static void put_u32(unsigned char* output, uint32_t value) {
    output[0] = (unsigned char)(value >> 24U);
    output[1] = (unsigned char)(value >> 16U);
    output[2] = (unsigned char)(value >> 8U);
    output[3] = (unsigned char)value;
}

static uint16_t get_u16(const unsigned char* input) {
    return (uint16_t)(((uint16_t)input[0] << 8U) | input[1]);
}

static uint32_t get_u32(const unsigned char* input) {
    return ((uint32_t)input[0] << 24U) | ((uint32_t)input[1] << 16U) | ((uint32_t)input[2] << 8U) |
           (uint32_t)input[3];
}

int main(void) {
    const record_v1 old = {513U, 1000};
    unsigned char bytes[7];
    bytes[0] = 1U;
    put_u16(&bytes[1], old.id);
    put_u32(&bytes[3], (uint32_t)old.score);

    record_v2 current = {0U, 0, false};
    if (bytes[0] != 1U) {
        return 1;
    }
    current.id = get_u16(&bytes[1]);
    current.score = (int32_t)get_u32(&bytes[3]);
    printf("version=%u\nid=%u\nscore=%d\nenabled=%d\n", bytes[0], current.id, current.score,
           current.enabled ? 1 : 0);
    return current.id == old.id && current.score == old.score && !current.enabled ? 0 : 1;
}
