#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct arena {
    unsigned char* memory;
    size_t capacity;
    size_t used;
    size_t allocations;
} arena;

static void* arena_alloc(arena* storage, size_t size, size_t alignment) {
    const size_t remainder = storage->used % alignment;
    const size_t padding = remainder == 0U ? 0U : alignment - remainder;
    if (padding > storage->capacity - storage->used ||
        size > storage->capacity - storage->used - padding) {
        return NULL;
    }
    const size_t offset = storage->used + padding;
    void* result = storage->memory + offset;
    storage->used = offset + size;
    ++storage->allocations;
    return result;
}

int main(void) {
    arena storage = {malloc(128U), 128U, 0U, 0U};
    if (storage.memory == NULL) {
        return 1;
    }
    if (arena_alloc(&storage, 1U, 1U) == NULL || arena_alloc(&storage, 8U, 8U) == NULL ||
        arena_alloc(&storage, 16U, 16U) == NULL) {
        free(storage.memory);
        return 1;
    }
    printf("allocations=%zu\n", storage.allocations);
    printf("used_bytes=%zu\n", storage.used);
    free(storage.memory);
    printf("released=once\n");
    return 0;
}
