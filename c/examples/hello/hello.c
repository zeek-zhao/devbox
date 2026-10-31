#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    printf("[hello] C17 from devbox\n");

    /* 指针与字符串：C 没有 std::string_view，长度靠 strlen 走一遍 */
    const char *name = "devbox";
    printf("strlen = %zu\n", strlen(name));

    /* 手动内存管理：malloc / free 必须配对，这是 C 与 C++ 最大的分野 */
    int *values = malloc(100 * sizeof(int));
    if (values == NULL) {
        fprintf(stderr, "malloc failed\n");
        return 1;
    }
    long sum = 0;
    for (int i = 0; i < 100; i++) {
        values[i] = i + 1;
        sum += values[i];
    }
    printf("sum(1..100) = %ld\n", sum);
    free(values);

    return 0;
}
