#include <stdio.h>

int main(void) {
#ifdef DEBUG
    puts("debug: enabled");
#else
    puts("debug: disabled");
#endif
    return 0;
}
