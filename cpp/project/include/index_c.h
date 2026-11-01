#ifndef DEVBOX_INDEX_C_H
#define DEVBOX_INDEX_C_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* L3-006-ffi-abi: opaque ownership, caller-owned error buffer, no STL or exceptions. */
typedef struct devbox_index devbox_index;
enum { DEVBOX_OK = 0, DEVBOX_INPUT = 1, DEVBOX_INTERNAL = 2 };
int devbox_index_open(const char* path, devbox_index** output, char* error, size_t capacity);
int devbox_index_count(const devbox_index* index, const char* word, size_t* count, char* error,
                       size_t capacity);
void devbox_index_close(devbox_index* index);

#ifdef __cplusplus
}
#endif
#endif
