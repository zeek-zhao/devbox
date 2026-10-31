#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct builder {
    char* data;
    size_t length;
    size_t capacity;
} builder;

static int append(builder* text, const char* part) {
    const size_t part_length = strlen(part);
    if (part_length > SIZE_MAX - text->length - 1U) {
        return 0;
    }
    const size_t required = text->length + part_length + 1U;
    if (required > text->capacity) {
        size_t next = text->capacity == 0U ? 16U : text->capacity;
        while (next < required) {
            if (next > SIZE_MAX / 2U) {
                next = required;
                break;
            }
            next *= 2U;
        }
        char* grown = realloc(text->data, next);
        if (grown == NULL) {
            return 0;
        }
        text->data = grown;
        text->capacity = next;
    }
    memcpy(text->data + text->length, part, part_length + 1U);
    text->length += part_length;
    return 1;
}

int main(void) {
    builder text = {NULL, 0U, 0U};
    char part[12];
    for (int i = 0; i < 100; ++i) {
        const int written = snprintf(part, sizeof(part), "segment-%02d;", i);
        if (written != 11 || !append(&text, part)) {
            free(text.data);
            return 1;
        }
    }
    uint64_t hash = UINT64_C(5381);
    for (size_t i = 0; i < text.length; ++i) {
        hash = hash * UINT64_C(33) + (unsigned char)text.data[i];
    }
    printf("length=%zu\nhash=%llu\n", text.length, (unsigned long long)hash);
    free(text.data);
    return 0;
}
