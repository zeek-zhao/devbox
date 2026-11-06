#include <stdio.h>

/* 超时与取消：两个不同的停止信号，都要「协作式」检查——
 *   - deadline：整批操作有时间预算。这里用虚拟步数时钟代替真实时间，
 *     保证输出确定；真实代码里换成 clock_gettime/CLOCK_MONOTONIC 判断即可。
 *   - cancel：外部主动要求停止，worker 在安全点（循环顶部）检查并尽快退出。
 * 两者都以专门错误码收场（TIMEOUT / CANCELLED），并如实报告已完成的步数——
 * 「做到哪一步」本身就是调用方决定续跑还是重来的依据。 */
enum { ERR_OK = 0, ERR_TIMEOUT = 4, ERR_CANCELLED = 6 };

typedef struct {
    int done_steps;
    int code;
} run_report_t;

/* deadline：预算 3 步，操作要跑 5 步 -> 第 4 步前超时 */
static run_report_t run_with_deadline(int total_steps, int budget) {
    run_report_t rep = { 0, ERR_OK };
    for (int step = 1; step <= total_steps; ++step) {
        if (rep.done_steps >= budget) {
            rep.code = ERR_TIMEOUT;
            printf("deadline hit after %d steps\n", rep.done_steps);
            return rep;
        }
        printf("step=%d ok\n", step);
        rep.done_steps = step;
    }
    return rep;
}

/* cancel：跑到第 2 步时外部置位取消标志，worker 在下一个安全点退出 */
static run_report_t run_with_cancel(int total_steps, int cancel_after) {
    run_report_t rep = { 0, ERR_OK };
    int cancel_requested = 0;
    for (int step = 1; step <= total_steps; ++step) {
        if (cancel_requested) {
            rep.code = ERR_CANCELLED;
            printf("cancel observed at safe point\n");
            return rep;
        }
        printf("step=%d ok\n", step);
        rep.done_steps = step;
        if (step == cancel_after) {
            cancel_requested = 1;   /* 模拟外部线程置位 */
        }
    }
    return rep;
}

static void report(const char *label, run_report_t rep) {
    printf("%s code=%d completed_steps=%d\n", label, rep.code, rep.done_steps);
}

int main(void) {
    report("deadline", run_with_deadline(5, 3));
    report("cancel", run_with_cancel(5, 2));
    return 0;
}
