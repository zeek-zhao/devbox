#include "pool/pool.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef union pool_block pool_block_t;

union pool_block {
    pool_block_t* next;
    max_align_t alignment;
};

struct pool {
    unsigned char* storage;
    size_t stride;
    size_t block_size;
    size_t block_count;
    size_t available;
    pool_block_t* free_list;
};

static bool aligned_size(size_t size, size_t alignment, size_t* result) {
    /* L3-016-overflow-safe-add: reject size plus alignment padding before it can wrap. */
    if (size > SIZE_MAX - (alignment - 1U)) {
        return false;
    }
    *result = (size + alignment - 1U) & ~(alignment - 1U);
    return true;
}

pool_t* pool_create(size_t block_size, size_t block_count) {
    size_t stride = 0U;
    if (block_size == 0U || block_count == 0U ||
        !aligned_size(block_size, _Alignof(max_align_t), &stride) ||
        stride > SIZE_MAX / block_count) {
        return NULL;
    }

    /* L1-001-types-sizes: allocate metadata using the actual pool object size. */
    /* L1-020-malloc-free: dynamically allocate pool metadata and backing storage. */
    pool_t* pool = calloc(1U, sizeof(*pool));
    if (pool == NULL) {
        return NULL;
    }
    pool->storage = aligned_alloc(_Alignof(max_align_t), stride * block_count);
    if (pool->storage == NULL) {
        free(pool);
        return NULL;
    }
    pool->stride = stride;
    pool->block_size = block_size;
    pool->block_count = block_count;
    pool->available = block_count;

    for (size_t i = 0U; i < block_count; ++i) {
        /* L1-005-pointer-arithmetic: stride locates each contiguous pool block. */
        /* L3-002-cache-locality: fixed-stride blocks occupy one contiguous allocation. */
        pool_block_t* block = (pool_block_t*)(void*)(pool->storage + i * stride);
        block->next = pool->free_list;
        pool->free_list = block;
    }
    return pool;
}

void pool_destroy(pool_t* pool) {
    if (pool != NULL) {
        /* L1-020-malloc-free: release both allocations owned by the pool. */
        free(pool->storage);
        free(pool);
    }
}

void* pool_acquire(pool_t* pool) {
    if (pool == NULL || pool->free_list == NULL) {
        return NULL;
    }
    pool_block_t* block = pool->free_list;
    pool->free_list = block->next;
    pool->available -= 1U;
    memset(block, 0, pool->block_size);
    return block;
}

bool pool_release(pool_t* pool, void* memory) {
    if (pool == NULL || memory == NULL) {
        return false;
    }
    uintptr_t address = (uintptr_t)memory;
    uintptr_t start = (uintptr_t)pool->storage;
    size_t total = pool->stride * pool->block_count;
    if (address < start || address - start >= total || (address - start) % pool->stride != 0U ||
        pool->available == pool->block_count) {
        return false;
    }
    /* L1-023-double-free-guard: reject blocks already present in the free list. */
    for (pool_block_t* item = pool->free_list; item != NULL; item = item->next) {
        if ((void*)item == memory) {
            return false;
        }
    }
    pool_block_t* block = memory;
    block->next = pool->free_list;
    pool->free_list = block;
    pool->available += 1U;
    return true;
}

size_t pool_available(const pool_t* pool) {
    return pool == NULL ? 0U : pool->available;
}

void arena_init(arena_t* arena, void* buffer, size_t capacity) {
    if (arena != NULL) {
        arena->data = buffer;
        arena->capacity = capacity;
        arena->used = 0U;
    }
}

void* arena_alloc(arena_t* arena, size_t size, size_t alignment) {
    if (arena == NULL || arena->data == NULL || size == 0U || alignment == 0U ||
        (alignment & (alignment - 1U)) != 0U) {
        return NULL;
    }
    uintptr_t base = (uintptr_t)arena->data;
    uintptr_t current = base + arena->used;
    /* L3-001-alignment: compute padding so each returned arena address meets alignment. */
    size_t padding = (size_t)((alignment - (current & (alignment - 1U))) & (alignment - 1U));
    if (padding > arena->capacity - arena->used || size > arena->capacity - arena->used - padding) {
        return NULL;
    }
    arena->used += padding + size;
    return arena->data + arena->used - size;
}

void arena_reset(arena_t* arena) {
    if (arena != NULL) {
        arena->used = 0U;
    }
}
