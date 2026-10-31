#include "index_c.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    char path[] = "/tmp/devbox-ffi-XXXXXX";
    int fd = mkstemp(path);
    assert(fd >= 0);
    const char text[] = "alpha beta\nalpha\n";
    assert(write(fd, text, sizeof(text) - 1) == (ssize_t)(sizeof(text) - 1));
    assert(close(fd) == 0);
    devbox_index* index = NULL;
    char error[128] = {0};
    size_t count = 0;
    assert(devbox_index_open(path, &index, error, sizeof(error)) == DEVBOX_OK);
    assert(index != NULL);
    assert(devbox_index_count(index, "ALPHA", &count, error, sizeof(error)) == DEVBOX_OK);
    assert(count == 2);
    assert(devbox_index_count(index, "missing", &count, error, sizeof(error)) == DEVBOX_OK);
    assert(count == 0);
    assert(devbox_index_count(index, "bad!", &count, error, sizeof(error)) == DEVBOX_INPUT);
    assert(strstr(error, "ASCII") != NULL);
    devbox_index_close(index);
    index = NULL;
    assert(unlink(path) == 0);
    assert(devbox_index_open(path, &index, error, sizeof(error)) == DEVBOX_INPUT);
    assert(index == NULL && strstr(error, path) != NULL);
    assert(devbox_index_open(NULL, &index, error, sizeof(error)) == DEVBOX_INPUT);
    assert(devbox_index_count(NULL, "alpha", &count, error, sizeof(error)) == DEVBOX_INPUT);
    devbox_index_close(NULL);
    return 0;
}
