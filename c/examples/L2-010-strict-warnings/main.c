#include <stdio.h>

int main(void) {
    int value = 1;
    {
        int value = 2;
        printf("inner=%d\n", value);
    }
    const int* read_only = &value;
    int* writable = (int*)read_only;
    signed char narrowed = 1000;
    printf("outer=%d writable=%d narrowed=%d\n", value, *writable, narrowed);
    return 0;
}
