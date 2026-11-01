#include <stddef.h>
#include <stdlib.h>

typedef struct record {
    int key;
    int original_index;
} record;

static void merge(record* values, record* temporary, size_t low, size_t middle, size_t high) {
    size_t left = low;
    size_t right = middle;
    size_t output = low;
    while (left < middle && right < high) {
        if (values[left].key <= values[right].key) {
            temporary[output++] = values[left++];
        } else {
            temporary[output++] = values[right++];
        }
    }
    while (left < middle) {
        temporary[output++] = values[left++];
    }
    while (right < high) {
        temporary[output++] = values[right++];
    }
    for (size_t i = low; i < high; ++i) {
        values[i] = temporary[i];
    }
}

static void merge_sort(record* values, record* temporary, size_t low, size_t high) {
    if (high - low < 2U) {
        return;
    }
    const size_t middle = low + (high - low) / 2U;
    merge_sort(values, temporary, low, middle);
    merge_sort(values, temporary, middle, high);
    merge(values, temporary, low, middle, high);
}

int stable_sort(record* values, size_t count) {
    if (count < 2U) {
        return 1;
    }
    record* temporary = malloc(count * sizeof(*temporary));
    if (temporary == NULL) {
        return 0;
    }
    merge_sort(values, temporary, 0U, count);
    free(temporary);
    return 1;
}
