#include <stddef.h>
#include <stdio.h>

typedef struct record {
    int key;
    int original_index;
} record;

int stable_sort(record* values, size_t count);

int main(void) {
    record values[] = {{2, 0}, {1, 1}, {2, 2}, {1, 3}, {3, 4}};
    const size_t count = sizeof(values) / sizeof(values[0]);
    if (!stable_sort(values, count)) {
        return 1;
    }
    printf("sorted=");
    for (size_t i = 0; i < count; ++i) {
        printf("%s%d:%d", i == 0U ? "" : ",", values[i].key, values[i].original_index);
    }
    printf("\n");
    return 0;
}
