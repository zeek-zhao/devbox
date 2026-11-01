#include <limits.h>
#include <stdio.h>

int main(void) {
    printf("CHAR_BIT=%d\n", CHAR_BIT);
    printf("char=%zu short=%zu int=%zu long=%zu long long=%zu\n", sizeof(char), sizeof(short),
           sizeof(int), sizeof(long), sizeof(long long));
    printf("float=%zu double=%zu void*=%zu\n", sizeof(float), sizeof(double), sizeof(void*));
    return 0;
}
