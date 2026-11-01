#ifndef DEVBOX_C_HTTP_H
#define DEVBOX_C_HTTP_H

/* L1-034-include-guard: prevent repeated inclusion of this public interface. */
#include "pool/pool.h"

#include <stdbool.h>
#include <stddef.h>

#define HTTP_REQUEST_CAPACITY 8192U
#define HTTP_RESPONSE_CAPACITY 1024U
#define HTTP_ARENA_CAPACITY 512U

typedef enum {
    HTTP_STATUS_OK = 200,
    HTTP_STATUS_BAD_REQUEST = 400,
    HTTP_STATUS_NOT_FOUND = 404,
    HTTP_STATUS_METHOD_NOT_ALLOWED = 405
} http_status_t;

typedef struct {
    char request[HTTP_REQUEST_CAPACITY];
    size_t request_length;
    char response[HTTP_RESPONSE_CAPACITY];
    size_t response_length;
    size_t response_offset;
    unsigned char arena_storage[HTTP_ARENA_CAPACITY];
    arena_t arena;
} http_connection_t;

void http_connection_init(http_connection_t* connection);
bool http_request_complete(const char* request, size_t length);
bool http_build_response(http_connection_t* connection);

#endif
