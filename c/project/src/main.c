#include "http/http.h"
#include "log/log.h"
#include "net/server.h"
#include "pool/pool.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static bool selftest_pool(void) {
    pool_t* pool = pool_create(sizeof(uint64_t), 2U);
    if (pool == NULL) {
        return false;
    }
    void* first = pool_acquire(pool);
    void* second = pool_acquire(pool);
    bool passed = first != NULL && second != NULL && first != second &&
                  pool_available(pool) == 0U && pool_release(pool, first) &&
                  !pool_release(pool, first) && pool_available(pool) == 1U;
    /* L2-009-leak-detection: release the heap-backed pool so external tools can verify cleanup. */
    pool_destroy(pool);

    unsigned char buffer[32];
    arena_t arena;
    arena_init(&arena, buffer, sizeof(buffer));
    void* aligned = arena_alloc(&arena, sizeof(uint64_t), _Alignof(uint64_t));
    passed = passed && aligned != NULL && (uintptr_t)aligned % _Alignof(uint64_t) == 0U &&
             arena_alloc(&arena, sizeof(buffer), 1U) == NULL;
    arena_reset(&arena);
    return passed && arena.used == 0U;
}

static bool selftest_http(void) {
    http_connection_t connection;
    http_connection_init(&connection);
    const char request[] = "GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n";
    (void)snprintf(connection.request, sizeof(connection.request), "%s", request);
    connection.request_length = strlen(connection.request);
    bool passed = http_request_complete(connection.request, connection.request_length) &&
                  http_build_response(&connection) &&
                  strstr(connection.response, "HTTP/1.1 200 OK\r\n") != NULL &&
                  strstr(connection.response, "\r\n\r\nok\n") != NULL;
    return passed;
}

static bool selftest_log(void) {
    log_ring_t log;
    log_init(&log);
    const char message[] = "message";
    for (size_t i = 0U; i < LOG_CAPACITY + 1U; ++i) {
        log_write(&log, message);
    }
    return log_count(&log) == LOG_CAPACITY &&
           strcmp(log_at(&log, LOG_CAPACITY - 1U), "message") == 0;
}

/* L0-hello：镜像与 runner 通路的锚点，原冒烟用例。 */
static int run_selftest(void) {
    /* L2-018-unit-test-harness: run deterministic checks for pool, arena, HTTP, and logging. */
    if (!selftest_pool() || !selftest_http() || !selftest_log()) {
        (void)fprintf(stderr, "selftest failed\n");
        return 1;
    }
    (void)puts("selftest: pool arena http log passed");
    return 0;
}

int main(int argc, char** argv) {
    /* L2-013-cli-args: recognize the one supported option and reject excess arguments. */
    if (argc == 2 && strcmp(argv[1], "--selftest") == 0) {
        return run_selftest();
    }
    if (argc > 2) {
        (void)fprintf(stderr, "usage: %s [--selftest]\n", argv[0]);
        return 2;
    }
    const char* configured_port = getenv("DEVBOX_PORT");
    if (configured_port == NULL) {
        configured_port = "18080";
    }
    uint16_t port = 0U;
    if (!server_parse_port(configured_port, &port)) {
        (void)fprintf(stderr, "invalid DEVBOX_PORT\n");
        return 2;
    }
    return server_run(port);
}
