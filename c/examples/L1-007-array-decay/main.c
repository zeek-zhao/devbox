#include <stdio.h>

static void show_parameter_size(int* arr) {
    printf("inside sizeof(arr)=%zu\n", sizeof(arr));
}

int main(void) {
    int values[5] = {0};

    show_parameter_size(values);
    printf("outside sizeof(values)=%zu\n", sizeof(values));
    return 0;
}
