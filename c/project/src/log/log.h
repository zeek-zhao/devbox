#ifndef DEVBOX_C_LOG_H
#define DEVBOX_C_LOG_H

#include <stddef.h>

#define LOG_CAPACITY 32U
#define LOG_MESSAGE_SIZE 128U

typedef struct {
    char messages[LOG_CAPACITY][LOG_MESSAGE_SIZE];
    size_t head;
    size_t count;
} log_ring_t;

void log_init(log_ring_t* log);
void log_write(log_ring_t* log, const char* restrict message);
size_t log_count(const log_ring_t* log);
const char* log_at(const log_ring_t* log, size_t index);
void log_flush(const log_ring_t* log);

#endif
