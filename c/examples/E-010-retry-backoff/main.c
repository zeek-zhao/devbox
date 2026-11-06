/* nanosleep/struct timespec 是 POSIX 接口：-std=c17 下需显式开启特性宏 */
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <time.h>

/* 重试与退避：只重试「可重试类」错误（超时、暂不可用），按固定退避表
 * 等待后再试；不可重试类错误（参数错）立即放弃——重试不会修好调用方的 bug。
 * 退避表是固定序列（100/200/400ms），输出只打印计划与结果，无时间戳。 */
enum { ERR_OK = 0, ERR_BAD_INPUT = 1, ERR_TIMEOUT = 4, ERR_UNAVAILABLE = 8 };

typedef struct { int code; int value; } op_result_t;

/* 模拟一个前两次超时、第三次成功的后端（按调用次数计数，确定性） */
static op_result_t flaky_backend(int attempt) {
    if (attempt < 3) {
        op_result_t r = { ERR_TIMEOUT, 0 };
        return r;
    }
    op_result_t r = { ERR_OK, 42 };
    return r;
}

/* 模拟一个参数错误的后端：永远失败且不可重试 */
static op_result_t strict_backend(int attempt) {
    (void)attempt;
    op_result_t r = { ERR_BAD_INPUT, 0 };
    return r;
}

static int retryable(int code) {
    return code == ERR_TIMEOUT || code == ERR_UNAVAILABLE;
}

static int run_with_retry(op_result_t (*backend)(int), const char *label) {
    const int backoff_ms[] = { 100, 200, 400 };
    const int nbackoff = (int)(sizeof backoff_ms / sizeof backoff_ms[0]);
    const int max_attempts = 4;

    for (int attempt = 1; attempt <= max_attempts; ++attempt) {
        op_result_t r = backend(attempt);
        if (r.code == ERR_OK) {
            printf("%s attempt=%d ok value=%d\n", label, attempt, r.value);
            return attempt;
        }
        if (!retryable(r.code) || attempt == max_attempts) {
            printf("%s attempt=%d code=%d give_up=1\n", label, attempt, r.code);
            return attempt;
        }
        int idx = (attempt - 1 < nbackoff) ? (attempt - 1) : (nbackoff - 1);
        printf("%s attempt=%d code=%d class=retryable backoff_ms=%d\n",
               label, attempt, r.code, backoff_ms[idx]);
        struct timespec ts = { backoff_ms[idx] / 1000,
                               (long)(backoff_ms[idx] % 1000) * 1000000L };
        nanosleep(&ts, NULL);
    }
    return max_attempts;
}

int main(void) {
    int used = run_with_retry(flaky_backend, "flaky");
    printf("flaky attempts_used=%d\n", used);
    used = run_with_retry(strict_backend, "strict");
    printf("strict attempts_used=%d\n", used);
    return 0;
}
