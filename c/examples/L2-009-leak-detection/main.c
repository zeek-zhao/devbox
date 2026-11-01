#include <stdlib.h>

int main(void) {
    void* allocation = malloc(128U);
    return allocation == NULL;
}
