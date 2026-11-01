#include <limits.h>
#include <stdio.h>

static int add_overflow(int left, int right, int* output) {
    if ((right > 0 && left > INT_MAX - right) || (right < 0 && left < INT_MIN - right)) {
        return 1;
    }
    *output = left + right;
    return 0;
}

int main(void) {
    int result = 0;
    if (add_overflow(1, 2, &result)) {
        return 1;
    }
    printf("1+2=ok:%d\n", result);
    if (!add_overflow(INT_MAX, 1, &result)) {
        return 1;
    }
    printf("INT_MAX+1=overflow\n");
    if (!add_overflow(INT_MIN, -1, &result)) {
        return 1;
    }
    printf("INT_MIN-1=overflow\n");
    return 0;
}
