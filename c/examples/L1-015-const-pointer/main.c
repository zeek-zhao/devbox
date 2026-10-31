#include <stdio.h>

int main(void) {
    int first = 10;
    int second = 20;
    const int* pointer_to_const = &first;
    int* const const_pointer = &first;
    const int* const const_pointer_to_const = &first;

    pointer_to_const = &second;
    *const_pointer = 11;
    printf("pointer to const now points to %d\n", *pointer_to_const);
    printf("const pointer changed value to %d\n", *const_pointer);
    printf("const pointer to const sees %d\n", *const_pointer_to_const);
    return 0;
}
