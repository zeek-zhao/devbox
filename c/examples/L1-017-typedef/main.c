#include <stdio.h>
#include <stdlib.h>

typedef struct foo foo_t;

struct foo {
    int value;
};

static foo_t* foo_create(int value) {
    foo_t* item = malloc(sizeof(*item));

    if (item != NULL) {
        item->value = value;
    }
    return item;
}

static int foo_value(const foo_t* item) {
    return item->value;
}

static void foo_destroy(foo_t* item) {
    free(item);
}

int main(void) {
    foo_t* item = foo_create(42);

    if (item == NULL) {
        return 1;
    }
    printf("opaque value=%d\n", foo_value(item));
    foo_destroy(item);
    return 0;
}
