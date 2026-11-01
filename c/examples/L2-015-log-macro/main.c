#include <stdio.h>

#define LOG(message) printf("%s:%d: %s\n", __FILE__, __LINE__, (message))

int main(void) {
    LOG("ready");
    return 0;
}
