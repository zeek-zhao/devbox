#include <stdio.h>
#include <string.h>

static int fail(FILE* file, const char* message) {
    if (file != NULL) {
        (void)fclose(file);
    }
    (void)fprintf(stderr, "file I/O: %s\n", message);
    return 1;
}

int main(int argc, char** argv) {
    static const unsigned char expected[] = {'C', 0, '1', '7', '\n'};
    unsigned char actual[sizeof(expected)];
    FILE* file;

    if (argc != 2) {
        (void)fprintf(stderr, "file I/O: expected a file path\n");
        return 1;
    }
    file = fopen(argv[1], "wb");
    if (file == NULL) {
        (void)fprintf(stderr, "file I/O: cannot open for writing\n");
        return 1;
    }
    if (fwrite(expected, 1U, sizeof(expected), file) != sizeof(expected)) {
        return fail(file, "short write");
    }
    if (fclose(file) != 0) {
        (void)fprintf(stderr, "file I/O: close after write failed\n");
        return 1;
    }

    file = fopen(argv[1], "rb");
    if (file == NULL) {
        (void)fprintf(stderr, "file I/O: cannot open for reading\n");
        return 1;
    }
    if (fread(actual, 1U, sizeof(actual), file) != sizeof(actual)) {
        return fail(file, "short read");
    }
    if (fclose(file) != 0) {
        (void)fprintf(stderr, "file I/O: close after read failed\n");
        return 1;
    }
    if (memcmp(expected, actual, sizeof(expected)) != 0) {
        (void)fprintf(stderr, "file I/O: data mismatch\n");
        return 1;
    }
    if (remove(argv[1]) != 0) {
        (void)fprintf(stderr, "file I/O: cannot remove test file\n");
        return 1;
    }
    puts("OK");
    return 0;
}
