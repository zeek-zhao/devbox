#include <stddef.h>
#include <stdio.h>

int main(void) {
    int values[] = {10, 20, 30};
    int* p = values;
    int* next = p + 1;
    ptrdiff_t bytes = (char*)next - (char*)p;

    printf("element step=%zu bytes\n", sizeof(*p));
    printf("char-pointer difference=%td bytes\n", bytes);
    return 0;
}
