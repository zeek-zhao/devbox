#include <stdio.h>

#ifndef DEVBOX_TRACE
#define DEVBOX_TRACE 0
#endif

#if DEVBOX_TRACE
#define TRACE(value) printf("trace:value=%d\n", (value))
#else
#define TRACE(value) ((void)0)
#endif

int main(void) {
    int counter = 0;
    TRACE(++counter);
#if DEVBOX_TRACE
    printf("enabled_counter=%d\n", counter);
#else
    printf("disabled_counter=%d\n", counter);
#endif
    return 0;
}
