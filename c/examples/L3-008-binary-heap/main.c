#include <stdio.h>

typedef struct heap {
    int values[16];
    size_t size;
} heap;

static void push(heap* values, int value) {
    size_t index = values->size++;
    while (index > 0U) {
        const size_t parent = (index - 1U) / 2U;
        if (values->values[parent] <= value) {
            break;
        }
        values->values[index] = values->values[parent];
        index = parent;
    }
    values->values[index] = value;
}

static int pop(heap* values) {
    const int result = values->values[0];
    const int tail = values->values[--values->size];
    if (values->size == 0U) {
        return result;
    }
    size_t index = 0U;
    while (index * 2U + 1U < values->size) {
        size_t child = index * 2U + 1U;
        if (child + 1U < values->size && values->values[child + 1U] < values->values[child]) {
            ++child;
        }
        if (tail <= values->values[child]) {
            break;
        }
        values->values[index] = values->values[child];
        index = child;
    }
    values->values[index] = tail;
    return result;
}

int main(void) {
    const int input[] = {7, 2, 9, 1, 5, 10, 4, 3, 8, 6};
    heap values = {{0}, 0U};
    for (size_t i = 0; i < sizeof(input) / sizeof(input[0]); ++i) {
        push(&values, input[i]);
    }
    printf("popped=");
    for (size_t i = 0; i < sizeof(input) / sizeof(input[0]); ++i) {
        printf("%s%d", i == 0U ? "" : ",", pop(&values));
    }
    printf("\n");
    return 0;
}
