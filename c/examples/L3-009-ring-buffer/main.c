#include <stdbool.h>
#include <stdio.h>

enum { CAPACITY = 3 };

typedef struct ring {
    int values[CAPACITY];
    size_t head;
    size_t tail;
    size_t count;
} ring;

static bool write_value(ring* buffer, int value) {
    if (buffer->count == CAPACITY) {
        return false;
    }
    buffer->values[buffer->tail] = value;
    buffer->tail = (buffer->tail + 1U) % CAPACITY;
    ++buffer->count;
    return true;
}

static bool read_value(ring* buffer, int* value) {
    if (buffer->count == 0U) {
        return false;
    }
    *value = buffer->values[buffer->head];
    buffer->head = (buffer->head + 1U) % CAPACITY;
    --buffer->count;
    return true;
}

int main(void) {
    ring buffer = {{0}, 0U, 0U, 0U};
    printf("writes=");
    for (int value = 1; value <= 5; ++value) {
        printf("%s%d", value == 1 ? "" : ",", write_value(&buffer, value) ? 1 : 0);
    }
    printf("\nreads=");
    for (size_t i = 0; i < CAPACITY; ++i) {
        int value = 0;
        if (!read_value(&buffer, &value)) {
            return 1;
        }
        printf("%s%d", i == 0U ? "" : ",", value);
    }
    printf("\nempty=%s\n", read_value(&buffer, &(int){0}) ? "no" : "yes");
    return buffer.count == 0U ? 0 : 1;
}
