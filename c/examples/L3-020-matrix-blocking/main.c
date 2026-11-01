#include <stdint.h>
#include <stdio.h>
#include <time.h>

enum { SIZE = 64, BLOCK = 16 };

static int left[SIZE][SIZE];
static int right[SIZE][SIZE];
static int64_t plain[SIZE][SIZE];
static int64_t blocked[SIZE][SIZE];

static void multiply_plain(void) {
    for (size_t i = 0; i < SIZE; ++i) {
        for (size_t k = 0; k < SIZE; ++k) {
            for (size_t j = 0; j < SIZE; ++j) {
                plain[i][j] += (int64_t)left[i][k] * right[k][j];
            }
        }
    }
}

static void multiply_blocked(void) {
    for (size_t ii = 0; ii < SIZE; ii += BLOCK) {
        for (size_t kk = 0; kk < SIZE; kk += BLOCK) {
            for (size_t jj = 0; jj < SIZE; jj += BLOCK) {
                const size_t i_end = ii + BLOCK < SIZE ? ii + BLOCK : SIZE;
                const size_t k_end = kk + BLOCK < SIZE ? kk + BLOCK : SIZE;
                const size_t j_end = jj + BLOCK < SIZE ? jj + BLOCK : SIZE;
                for (size_t i = ii; i < i_end; ++i) {
                    for (size_t k = kk; k < k_end; ++k) {
                        for (size_t j = jj; j < j_end; ++j) {
                            blocked[i][j] += (int64_t)left[i][k] * right[k][j];
                        }
                    }
                }
            }
        }
    }
}

static int64_t checksum(const int64_t matrix[SIZE][SIZE]) {
    int64_t sum = 0;
    for (size_t i = 0; i < SIZE; ++i) {
        for (size_t j = 0; j < SIZE; ++j) {
            sum += matrix[i][j];
        }
    }
    return sum;
}

int main(void) {
    for (size_t i = 0; i < SIZE; ++i) {
        for (size_t j = 0; j < SIZE; ++j) {
            left[i][j] = (int)((i + j) % 7U);
            right[i][j] = (int)((i * 2U + j) % 5U);
        }
    }
    const clock_t plain_start = clock();
    multiply_plain();
    const clock_t plain_end = clock();
    const clock_t blocked_start = clock();
    multiply_blocked();
    const clock_t blocked_end = clock();
    const int64_t plain_sum = checksum(plain);
    const int64_t blocked_sum = checksum(blocked);
    printf("checksum=%lld\nblocked_matches=%s\n", (long long)plain_sum,
           plain_sum == blocked_sum ? "yes" : "no");
    fprintf(stderr, "plain_ticks=%ld blocked_ticks=%ld\n", (long)(plain_end - plain_start),
            (long)(blocked_end - blocked_start));
    return plain_sum == blocked_sum ? 0 : 1;
}
