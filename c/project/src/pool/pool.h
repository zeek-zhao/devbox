#ifndef DEVBOX_C_POOL_H
#define DEVBOX_C_POOL_H

#include <stdbool.h>
#include <stddef.h>

typedef struct pool pool_t;
typedef struct arena arena_t;

struct arena {
    unsigned char* data;
    size_t capacity;
    size_t used;
};

pool_t* pool_create(size_t block_size, size_t block_count);
void pool_destroy(pool_t* pool);
void* pool_acquire(pool_t* pool);
bool pool_release(pool_t* pool, void* block);
size_t pool_available(const pool_t* pool);
void arena_init(arena_t* arena, void* buffer, size_t capacity);
void* arena_alloc(arena_t* arena, size_t size, size_t alignment);
void arena_reset(arena_t* arena);

#endif
