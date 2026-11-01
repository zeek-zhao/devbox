#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>

enum { BLOCK_COUNT = 4, PAYLOAD_SIZE = 24 };

typedef union block {
    max_align_t alignment;
    unsigned char payload[PAYLOAD_SIZE];
} block;

typedef struct pool {
    block blocks[BLOCK_COUNT];
    size_t free_indices[BLOCK_COUNT];
    size_t available;
} pool;

static void pool_init(pool* storage) {
    storage->available = BLOCK_COUNT;
    for (size_t i = 0; i < BLOCK_COUNT; ++i) {
        storage->free_indices[i] = BLOCK_COUNT - 1U - i;
    }
}

static void* pool_alloc(pool* storage) {
    if (storage->available == 0U) {
        return NULL;
    }
    const size_t index = storage->free_indices[--storage->available];
    return storage->blocks[index].payload;
}

static bool pool_free(pool* storage, void* pointer) {
    for (size_t i = 0; i < BLOCK_COUNT; ++i) {
        if (pointer == storage->blocks[i].payload) {
            if (storage->available == BLOCK_COUNT) {
                return false;
            }
            storage->free_indices[storage->available++] = i;
            return true;
        }
    }
    return false;
}

int main(void) {
    pool storage;
    pool_init(&storage);
    void* first = pool_alloc(&storage);
    void* second = pool_alloc(&storage);
    if (first == NULL || second == NULL || !pool_free(&storage, first)) {
        return 1;
    }
    void* third = pool_alloc(&storage);
    printf("first_reused=%s\n", third == first ? "yes" : "no");
    printf("live_blocks_distinct=%s\n", second != third ? "yes" : "no");
    return third == first && second != third ? 0 : 1;
}
