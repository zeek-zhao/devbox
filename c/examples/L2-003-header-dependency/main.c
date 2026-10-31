#include <stdio.h>

#include "alpha.h"
#include "beta.h"

int main(void) {
    const struct beta_value value = {42};
    printf("value=%d\n", alpha_value(&value));
    return 0;
}
