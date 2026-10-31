#include <stddef.h>
#include <stdio.h>

int main(void) {
    int values[] = {10, 20, 30, 40, 50};
    int* first = &values[1];
    int* last = &values[4];
    ptrdiff_t elements = last - first;

    printf("element difference=%td\n", elements);
    return 0;
}
