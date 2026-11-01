#include <assert.h>
#include <stdio.h>

int main(void) {
    int checks = 0;
    assert(++checks == 1);
    printf("assertions: %d\n", checks);
    return 0;
}
