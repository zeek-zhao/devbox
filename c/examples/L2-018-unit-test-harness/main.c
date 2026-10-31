#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned int assertions_run;

static void test_assert(int condition, int line) {
    if (condition == 0) {
        (void)fprintf(stderr, "test failure at line %d\n", line);
        exit(EXIT_FAILURE);
    }
    ++assertions_run;
}

#define TEST_ASSERT(condition) test_assert((condition), __LINE__)

static int add(int left, int right) {
    return left + right;
}

int main(void) {
    TEST_ASSERT(add(2, 3) == 5);
    TEST_ASSERT(strcmp("C17", "C17") == 0);
    TEST_ASSERT(10U / 2U == 5U);
    printf("%u passed\n", assertions_run);
    return 0;
}
