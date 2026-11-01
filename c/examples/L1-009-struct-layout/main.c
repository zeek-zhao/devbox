#include <stddef.h>
#include <stdio.h>

struct Record {
    char tag;
    int count;
    double ratio;
};

int main(void) {
    printf("sizeof(struct Record)=%zu\n", sizeof(struct Record));
    printf("offsetof(tag)=%zu\n", offsetof(struct Record, tag));
    printf("offsetof(count)=%zu\n", offsetof(struct Record, count));
    printf("offsetof(ratio)=%zu\n", offsetof(struct Record, ratio));
    return 0;
}
