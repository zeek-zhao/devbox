#include <stddef.h>

static void crash_here(void) {
    volatile int* pointer = NULL;
    *pointer = 1;
}

int main(void) {
    crash_here();
    return 0;
}
