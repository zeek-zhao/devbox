#include <stdio.h>

struct small_value {
    int number;
};

struct large_value {
    long numbers[4];
};

static int inspect_small(struct small_value value) {
    return value.number;
}

static long inspect_large(struct large_value value) {
    return value.numbers[0] + value.numbers[1] + value.numbers[2] + value.numbers[3];
}

int main(void) {
    const struct small_value small = {7};
    const struct large_value large = {{1L, 2L, 3L, 4L}};

    printf("small_size=%zu large_size=%zu values=%d,%ld\n", sizeof(small), sizeof(large),
           inspect_small(small), inspect_large(large));
    return 0;
}
