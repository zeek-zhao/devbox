#include <stdio.h>
#include <string.h>

/* 传播与包装：错误沿调用链向上传播时，每一层只做两件事——
 *   1. 给消息补上本层操作名前缀（加上下文，不是改答案）；
 *   2. 原样透传根因码。
 * 包装不改变错误身份：上游依旧按根因码做精确匹配，
 * 而消息链则保留了完整路径，排障时一眼看到「哪条链路、断在哪一节」。 */
enum { ERR_OK = 0, ERR_NOT_FOUND = 3 };

#define MAX_FRAMES 4

typedef struct {
    int code;      /* 根因码：层层透传，不改写 */
    char msg[160]; /* 根因消息 + 各层前缀，展示用 */
    int depth;     /* 已包装层数 */
} error_t;

static error_t err_root(int code, const char* msg) {
    error_t e;
    e.code = code;
    e.depth = 0;
    snprintf(e.msg, sizeof e.msg, "%s", msg);
    return e;
}

/* 前缀写入用显式长度检查的 memcpy，消息尾部按需截断（前缀优先保完整），
 * 边界手工核算，避开 snprintf 的截断告警与隐藏的溢出路径。 */
static error_t wrap(error_t e, const char* op) {
    char buf[sizeof e.msg];
    size_t cap = sizeof e.msg;
    size_t off = 0;

    size_t plen = strlen(op);
    if (plen > cap - 3) {
        plen = cap - 3; /* 预留 ": " 与 NUL */
    }
    memcpy(buf, op, plen);
    off = plen;
    buf[off++] = ':';
    buf[off++] = ' ';

    size_t mlen = strlen(e.msg);
    if (mlen > cap - off - 1) {
        mlen = cap - off - 1;
    }
    memcpy(buf + off, e.msg, mlen);
    off += mlen;
    buf[off] = '\0';

    memcpy(e.msg, buf, off + 1);
    if (e.depth < MAX_FRAMES) {
        ++e.depth;
    }
    return e;
}

static error_t read_config(const char* path) {
    /* 模拟底层 IO 失败：真实代码里这里是 errno 转换后的错误值（见 E-009） */
    (void)path;
    return err_root(ERR_NOT_FOUND, "open failed");
}

static error_t load_settings(const char* path) {
    error_t e = read_config(path);
    if (e.code != ERR_OK) {
        return wrap(e, "read_config");
    }
    return e;
}

static error_t bootstrap(const char* path) {
    error_t e = load_settings(path);
    if (e.code != ERR_OK) {
        return wrap(e, "load_settings");
    }
    return e;
}

int main(void) {
    error_t e = bootstrap("/etc/app/settings.conf");
    if (e.code == ERR_OK) {
        printf("boot=ok\n");
        return 0;
    }
    printf("error_chain=%s\n", e.msg);
    printf("root_code=%d depth=%d\n", e.code, e.depth);
    return 0;
}
