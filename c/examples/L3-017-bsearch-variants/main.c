#include <stddef.h>
#include <stdio.h>

static size_t lower_bound(const int* values, size_t size, int target) {
    size_t low = 0U;
    size_t high = size;
    while (low < high) {
        const size_t middle = low + (high - low) / 2U;
        if (values[middle] < target) {
            low = middle + 1U;
        } else {
            high = middle;
        }
    }
    return low;
}

static size_t upper_bound(const int* values, size_t size, int target) {
    size_t low = 0U;
    size_t high = size;
    while (low < high) {
        const size_t middle = low + (high - low) / 2U;
        if (values[middle] <= target) {
            low = middle + 1U;
        } else {
            high = middle;
        }
    }
    return low;
}

static ptrdiff_t find_value(const int* values, size_t size, int target) {
    const size_t index = lower_bound(values, size, target);
    if (index == size || values[index] != target) {
        return -1;
    }
    return (ptrdiff_t)index;
}

int main(void) {
    const int values[] = {1, 2, 2, 2, 4, 7};
    const size_t size = sizeof(values) / sizeof(values[0]);
    printf("lower_bound(2)=%zu\n", lower_bound(values, size, 2));
    printf("upper_bound(2)=%zu\n", upper_bound(values, size, 2));
    printf("find(2)=%td\n", find_value(values, size, 2));
    printf("find(3)=%td\n", find_value(values, size, 3));
    return 0;
}
