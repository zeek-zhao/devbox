#include <stddef.h>

int byte_sum(const unsigned char *data, size_t len) {
    int sum = 0;
    for (size_t index = 0; index < len; index++) {
        sum += data[index];
    }
    return sum;
}
