#include <stdio.h>

static int add(int left, int right) {
    return left + right;
}

static int subtract(int left, int right) {
    return left - right;
}

static int dispatch(char operation, int left, int right) {
    int (*op)(int, int) = operation == '+' ? add : subtract;

    return op(left, right);
}

int main(void) {
    printf("12 + 5 = %d\n", dispatch('+', 12, 5));
    printf("12 - 5 = %d\n", dispatch('-', 12, 5));
    return 0;
}
