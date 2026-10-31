#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct array {
    int* items;
    size_t size;
    size_t capacity;
    size_t growths;
    size_t capacities[16];
} array;

static int push(array* values, int item) {
    if (values->size == values->capacity) {
        const size_t next = values->capacity == 0U ? 1U : values->capacity * 2U;
        if (next > SIZE_MAX / sizeof(*values->items)) {
            return 0;
        }
        int* grown = realloc(values->items, next * sizeof(*values->items));
        if (grown == NULL) {
            return 0;
        }
        values->items = grown;
        values->capacity = next;
        values->capacities[values->growths++] = next;
    }
    values->items[values->size++] = item;
    return 1;
}

int main(void) {
    array values = {0};
    for (int i = 0; i < 1000; ++i) {
        if (!push(&values, i)) {
            free(values.items);
            return 1;
        }
    }
    printf("growth=");
    for (size_t i = 0; i < values.growths; ++i) {
        printf("%s%zu", i == 0U ? "" : ",", values.capacities[i]);
    }
    printf("\nsize=%zu\n", values.size);
    const int valid = values.size == 1000U && values.items[999] == 999;
    free(values.items);
    return valid ? 0 : 1;
}
