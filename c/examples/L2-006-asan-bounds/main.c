#include <stdlib.h>

int main(void) {
    int* values = malloc(4U * sizeof(*values));
    if (values == NULL) {
        return 2;
    }
    values[4] = 7;
    free(values);
    return 0;
}
