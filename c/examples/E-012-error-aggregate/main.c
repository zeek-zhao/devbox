/* pthread 是 POSIX 接口：-std=c17 下需显式开启特性宏 */
#define _POSIX_C_SOURCE 200809L
#include <pthread.h>
#include <stdio.h>

/* 并发错误聚合：N 个 worker 并发执行，各自把结果写进自己的槽位
 * （无共享写冲突，无需锁），主线程 join 后统一聚合：
 *   - 每个 worker 的结果按槽位下标固定顺序打印，与调度完成次序无关；
 *   - 汇总 ok/failed 计数与按码分布，一次呈现全部失败而不是只报第一个。
 * 关键纪律：聚合只发生在 join 之后——读到一半的结果比聚合慢更危险。 */
enum { ERR_OK = 0, ERR_TIMEOUT = 4, ERR_IO = 7 };

#define NWORKERS 4

typedef struct {
    int worker_id;
    int code;
} worker_result_t;

static worker_result_t results[NWORKERS];

/* 每个 worker 一种结局：0 成功、1 超时、2 IO 错、3 超时（确定性模拟） */
static void *worker(void *arg) {
    int id = (int)(long)arg;
    results[id].worker_id = id;
    switch (id) {
        case 0:  results[id].code = ERR_OK;      break;
        case 1:  results[id].code = ERR_TIMEOUT; break;
        case 2:  results[id].code = ERR_IO;      break;
        default: results[id].code = ERR_TIMEOUT; break;
    }
    return NULL;
}

static const char *code_name(int code) {
    switch (code) {
        case ERR_OK:      return "OK";
        case ERR_TIMEOUT: return "TIMEOUT";
        case ERR_IO:      return "IO";
    }
    return "UNKNOWN";
}

int main(void) {
    pthread_t threads[NWORKERS];

    for (int i = 0; i < NWORKERS; ++i) {
        pthread_create(&threads[i], NULL, worker, (void *)(long)i);
    }
    for (int i = 0; i < NWORKERS; ++i) {
        pthread_join(threads[i], NULL);
    }

    int ok = 0, failed = 0, timeouts = 0, io = 0;
    for (int i = 0; i < NWORKERS; ++i) {
        printf("worker=%d err=%s\n", results[i].worker_id, code_name(results[i].code));
        if (results[i].code == ERR_OK) {
            ++ok;
        } else {
            ++failed;
            if (results[i].code == ERR_TIMEOUT) {
                ++timeouts;
            }
            if (results[i].code == ERR_IO) {
                ++io;
            }
        }
    }
    printf("summary total=%d ok=%d failed=%d by_code TIMEOUT=%d IO=%d\n",
           NWORKERS, ok, failed, timeouts, io);
    return 0;
}
