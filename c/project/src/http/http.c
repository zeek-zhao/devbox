/* L2-003-header-dependency: this implementation uses the module's public declarations. */
#include "http/http.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* L1-017-typedef: name the common route callback signature. */
typedef const char* (*route_handler_t)(void);

typedef struct {
    const char* path;
    route_handler_t handler;
} route_t;

static const char* index_handler(void) {
    return "devbox-c\n";
}

/* L1-031-internal-linkage: this built-in handler is private to this translation unit. */
static const char* health_handler(void) {
    return "ok\n";
}

/* L1-015-const-pointer: fixed route entries and their targets are read-only. */
static const route_t routes[] = {
    {.path = "/", .handler = index_handler},
    {.path = "/health", .handler = health_handler},
};

void http_connection_init(http_connection_t* connection) {
    memset(connection, 0, sizeof(*connection));
    arena_init(&connection->arena, connection->arena_storage, sizeof(connection->arena_storage));
}

bool http_request_complete(const char* request, size_t length) {
    if (length < 4U) {
        return false;
    }
    return strstr(request, "\r\n\r\n") != NULL;
}

static bool parse_request_line(char* line, char** method, char** target) {
    /* L1-008-string-functions: delimit the request line using string search. */
    char* first_space = strchr(line, ' ');
    if (first_space == NULL) {
        return false;
    }
    *first_space = '\0';
    char* path = first_space + 1;
    char* second_space = strchr(path, ' ');
    if (second_space == NULL) {
        return false;
    }
    *second_space = '\0';
    char* version = second_space + 1;
    if (strchr(version, ' ') != NULL ||
        (strcmp(version, "HTTP/1.1") != 0 && strcmp(version, "HTTP/1.0") != 0) || path[0] != '/') {
        return false;
    }
    *method = line;
    *target = path;
    return true;
}

bool http_build_response(http_connection_t* connection) {
    char* line_end = strstr(connection->request, "\r\n");
    if (line_end == NULL) {
        return false;
    }
    *line_end = '\0';
    char* method = NULL;
    char* target = NULL;
    http_status_t status = HTTP_STATUS_OK;
    const char* body = NULL;

    if (!parse_request_line(connection->request, &method, &target)) {
        /* L3-022-error-code-design: map malformed request input to the explicit 400 status. */
        status = HTTP_STATUS_BAD_REQUEST;
        body = "bad request\n";
    } else if (strcmp(method, "GET") != 0) {
        status = HTTP_STATUS_METHOD_NOT_ALLOWED;
        body = "method not allowed\n";
    } else {
        /* L3-004-arena-allocator: keep the copied route path in connection-scoped storage. */
        char* path_copy = arena_alloc(&connection->arena, strlen(target) + 1U, 1U);
        if (path_copy == NULL) {
            return false;
        }
        (void)snprintf(path_copy, strlen(target) + 1U, "%s", target);
        status = HTTP_STATUS_NOT_FOUND;
        body = "not found\n";
        for (size_t i = 0U; i < sizeof(routes) / sizeof(routes[0]); ++i) {
            if (strcmp(path_copy, routes[i].path) == 0) {
                /* L1-016-function-pointers: invoke the handler selected by the route table. */
                body = routes[i].handler();
                status = HTTP_STATUS_OK;
                break;
            }
        }
    }

    const char* reason = "OK";
    if (status == HTTP_STATUS_BAD_REQUEST) {
        reason = "Bad Request";
    } else if (status == HTTP_STATUS_NOT_FOUND) {
        reason = "Not Found";
    } else if (status == HTTP_STATUS_METHOD_NOT_ALLOWED) {
        reason = "Method Not Allowed";
    }
    /* L2-016-print-formats: %zu formats the size_t response-body length. */
    int written = snprintf(connection->response, sizeof(connection->response),
                           "HTTP/1.1 %d %s\r\n"
                           "Content-Type: text/plain; charset=utf-8\r\n"
                           "Content-Length: %zu\r\n"
                           "Connection: close\r\n\r\n%s",
                           (int)status, reason, strlen(body), body);
    if (written < 0 || (size_t)written >= sizeof(connection->response)) {
        return false;
    }
    connection->response_length = (size_t)written;
    connection->response_offset = 0U;
    return true;
}
