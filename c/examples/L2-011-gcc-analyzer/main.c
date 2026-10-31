#include <stdlib.h>

static void leak_one_allocation(void) {
    char* buffer = malloc(16U);
    if (buffer == NULL) {
        return;
    }
    buffer[0] = 'x';
}

int main(void) {
    leak_one_allocation();
    return 0;
}
