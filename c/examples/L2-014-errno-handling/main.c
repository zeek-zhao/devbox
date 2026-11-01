#include <errno.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char** argv) {
    FILE* file;
    int error_code;

    if (argc != 2) {
        (void)fprintf(stderr, "errno: expected a file path\n");
        return 1;
    }
    file = fopen(argv[1], "r");
    if (file != NULL) {
        (void)fclose(file);
        (void)fprintf(stderr, "errno: test file unexpectedly exists\n");
        return 1;
    }
    error_code = errno;
    printf("errno=%d message=%s\n", error_code, strerror(error_code));
    return 0;
}
