#include <stdio.h>
#include <time.h>

enum { SIZE = 768, REPEATS = 12 };
static int matrix[SIZE][SIZE];
static volatile long long sink;

static double row_sum(void) {
    long long sum = 0;
    for (int repeat = 0; repeat < REPEATS; ++repeat) {
        for (int i = 0; i < SIZE; ++i) {
            for (int j = 0; j < SIZE; ++j) {
                sum += matrix[i][j];
            }
        }
    }
    sink = sum;
    return (double)sum;
}

static double column_sum(void) {
    long long sum = 0;
    for (int repeat = 0; repeat < REPEATS; ++repeat) {
        for (int j = 0; j < SIZE; ++j) {
            for (int i = 0; i < SIZE; ++i) {
                sum += matrix[i][j];
            }
        }
    }
    sink = sum;
    return (double)sum;
}

int main(void) {
    for (int i = 0; i < SIZE; ++i) {
        for (int j = 0; j < SIZE; ++j) {
            matrix[i][j] = (i + j) % 17;
        }
    }

    const clock_t row_start = clock();
    const double rows = row_sum();
    const clock_t row_end = clock();
    const clock_t column_start = clock();
    const double columns = column_sum();
    const clock_t column_end = clock();
    const double row_time = (double)(row_end - row_start) / CLOCKS_PER_SEC;
    const double column_time = (double)(column_end - column_start) / CLOCKS_PER_SEC;

    printf("checksums_match=%s\n", rows == columns ? "yes" : "no");
    printf("row_not_slower=%s\n", row_time <= column_time ? "yes" : "no");
    return rows == columns && row_time <= column_time ? 0 : 1;
}
