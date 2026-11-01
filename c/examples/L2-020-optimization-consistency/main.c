#include <stdio.h>

int main(void) {
    unsigned int checksum = 0U;
    for (unsigned int value = 1U; value <= 100U; ++value) {
        checksum += value * value;
    }
    printf("checksum=%u\n", checksum);
    return 0;
}
