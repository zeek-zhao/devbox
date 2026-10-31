#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

int main(void) {
    uint64_t count = UINT64_C(1234567890123456789);
    int32_t offset = INT32_C(-123456789);

    printf("uint64=%" PRIu64 "\n", count);
    printf("int32=%" PRId32 "\n", offset);
    return 0;
}
