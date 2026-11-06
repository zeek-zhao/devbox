#include <stdio.h>

/* 可观测性：错误发生时发结构化单行事件（seq/level/op/code/attempt），
 * 并同步维护计数器。事件行是空格分隔的 KV，机器可解析、可入日志管道；
 * 计数器驱动阈值告警。用虚拟时钟（事件序号）代替真实时间戳，输出确定。 */
enum { ERR_OK = 0, ERR_TIMEOUT = 4, ERR_IO = 7 };

typedef struct {
    long seq;         /* 虚拟时钟：事件序号 */
    int timeouts;
    int io_errors;
    int total;
} error_metrics_t;

static void emit(error_metrics_t *m, const char *level, const char *op,
                 int code, int attempt) {
    ++m->seq;
    ++m->total;
    if (code == ERR_TIMEOUT) {
        ++m->timeouts;
    }
    if (code == ERR_IO) {
        ++m->io_errors;
    }
    printf("event seq=%ld level=%s op=%s code=%d attempt=%d\n",
           m->seq, level, op, code, attempt);
}

int main(void) {
    error_metrics_t m = { 0, 0, 0, 0 };

    emit(&m, "warning", "http-get", ERR_TIMEOUT, 1);
    emit(&m, "warning", "http-get", ERR_TIMEOUT, 2);
    emit(&m, "error",   "disk-flush", ERR_IO, 1);
    emit(&m, "info",    "http-get", ERR_OK, 3);

    printf("metrics total=%d timeouts=%d io_errors=%d\n",
           m.total, m.timeouts, m.io_errors);
    return 0;
}
