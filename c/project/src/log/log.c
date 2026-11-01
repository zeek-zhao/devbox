#include "log/log.h"

#include <stdio.h>
#include <string.h>

void log_init(log_ring_t* log) {
    if (log != NULL) {
        memset(log, 0, sizeof(*log));
    }
}

void log_write(log_ring_t* log, const char* restrict message) {
    if (log == NULL || message == NULL) {
        return;
    }
    size_t slot = (log->head + log->count) % LOG_CAPACITY;
    /* L3-009-ring-buffer: on capacity, overwrite the oldest slot and advance the head. */
    if (log->count == LOG_CAPACITY) {
        slot = log->head;
        log->head = (log->head + 1U) % LOG_CAPACITY;
    } else {
        log->count += 1U;
    }
    (void)snprintf(log->messages[slot], LOG_MESSAGE_SIZE, "%s", message);
}

size_t log_count(const log_ring_t* log) {
    return log == NULL ? 0U : log->count;
}

const char* log_at(const log_ring_t* log, size_t index) {
    if (log == NULL || index >= log->count) {
        return NULL;
    }
    return log->messages[(log->head + index) % LOG_CAPACITY];
}

void log_flush(const log_ring_t* log) {
    for (size_t i = 0U; i < log_count(log); ++i) {
        const char* message = log_at(log, i);
        if (message != NULL) {
            (void)fprintf(stderr, "%s\n", message);
        }
    }
}
