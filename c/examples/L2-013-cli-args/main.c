#include <stdio.h>
#include <string.h>

int main(int argc, char** argv) {
    const char* name = NULL;
    int verbose = 0;

    for (int index = 1; index < argc; ++index) {
        if (strncmp(argv[index], "--name=", 7U) == 0 && argv[index][7] != '\0') {
            name = argv[index] + 7;
        } else if (strcmp(argv[index], "-v") == 0) {
            verbose = 1;
        } else {
            (void)fprintf(stderr, "cli: unknown or invalid argument\n");
            return 1;
        }
    }
    if (name == NULL) {
        (void)fprintf(stderr, "cli: --name is required\n");
        return 1;
    }
    printf("name=%s verbose=%s\n", name, verbose != 0 ? "yes" : "no");
    return 0;
}
