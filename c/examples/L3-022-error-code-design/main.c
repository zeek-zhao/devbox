#include <stdio.h>

typedef enum err { ERR_OK, ERR_INVALID, ERR_NOT_FOUND } err;

static err lookup(int key, int* value) {
    if (key < 0) {
        return ERR_INVALID;
    }
    if (key != 1) {
        return ERR_NOT_FOUND;
    }
    *value = 42;
    return ERR_OK;
}

static void report(int key) {
    int value = 0;
    const err result = lookup(key, &value);
    switch (result) {
    case ERR_OK:
        printf("success:value=%d\n", value);
        break;
    case ERR_INVALID:
        printf("invalid:negative-key\n");
        break;
    case ERR_NOT_FOUND:
        printf("not-found:key=%d\n", key);
        break;
    default:
        printf("unknown-error\n");
        break;
    }
}

int main(void) {
    report(1);
    report(-1);
    report(7);
    return 0;
}
