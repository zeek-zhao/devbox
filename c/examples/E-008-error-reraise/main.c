#include <stdio.h>

/* 不吞错与重抛：中间层收到错误，可以记录、可以补充上下文，
 * 但必须把错误继续向上传播（return 同一个码），不能 return 0 让它消失。
 * 对照组演示「吞错」的可观察后果：顶层拿到 0，以为成功，
 * 错误被静默丢弃，故障被推迟到更难查的地方。 */
enum { ERR_OK = 0, ERR_BACKEND_DOWN = 9 };

static int fetch_from_backend(int backend_up) {
    return backend_up ? ERR_OK : ERR_BACKEND_DOWN;
}

/* 正确：记录后重抛，码原样向上传播 */
static int middle_reraise(int backend_up) {
    int rc = fetch_from_backend(backend_up);
    if (rc != ERR_OK) {
        printf("  [mid] observed code=%d re-raising\n", rc);
        return rc; /* 重抛：码不变 */
    }
    return ERR_OK;
}

/* 反例：吞错——记了日志却 return 0 */
static int middle_swallow(int backend_up) {
    int rc = fetch_from_backend(backend_up);
    if (rc != ERR_OK) {
        printf("  [mid] observed code=%d but returning 0 (SWALLOWED)\n", rc);
        return 0;
    }
    return 0;
}

static void top(const char* label, int (*mid)(int), int backend_up) {
    int rc = mid(backend_up);
    if (rc == ERR_OK) {
        printf("[%s] top sees success (code=0)\n", label);
    } else {
        printf("[%s] top sees code=%d -> fail over to replica\n", label, rc);
    }
}

int main(void) {
    printf("-- reraise path --\n");
    top("reraise", middle_reraise, 0);
    printf("-- swallow path --\n");
    top("swallow", middle_swallow, 0);
    return 0;
}
