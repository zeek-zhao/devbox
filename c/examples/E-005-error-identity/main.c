#include <stdio.h>
#include <string.h>

/* 错误身份判定：判定「这是不是那个错」，用码（哨兵比较），不用消息文本。
 * 文本匹配的陷阱用两组真实反例定量展示：
 *   - 锁等待超时（LOCK_STALL）消息里也有 "timed out"，
 *     按文本猜会被误判成网络超时（NET_TIMEOUT）。 */
enum { ERR_OK = 0, ERR_NET_TIMEOUT = 4, ERR_LOCK_STALL = 5 };

typedef struct { int code; const char *op; const char *msg; } error_t;

/* 哨兵错误：身份的锚点，只定义一次；err_is 只比码。 */
static const error_t SENTINEL_NET_TIMEOUT = { ERR_NET_TIMEOUT, "http-get", "" };

static int err_is(error_t e, const error_t *sentinel) {
    return e.code == sentinel->code;
}

static const char *classify_by_code(error_t e) {
    switch (e.code) {
        case ERR_OK:          return "OK";
        case ERR_NET_TIMEOUT: return "NET_TIMEOUT";
        case ERR_LOCK_STALL:  return "LOCK_STALL";
    }
    return "UNKNOWN";
}

/* 反例：按消息文本猜类别。 */
static const char *classify_by_text(error_t e) {
    if (strstr(e.msg, "timed out") != NULL) {
        return "NET_TIMEOUT";
    }
    return "UNKNOWN";
}

int main(void) {
    const error_t cases[] = {
        { ERR_OK,          "ping",     "reply received" },
        { ERR_NET_TIMEOUT, "http-get", "connect timed out after 3000ms" },
        { ERR_LOCK_STALL,  "db-txn",   "lock wait timed out after 5000ms" },
    };
    const int n = (int)(sizeof cases / sizeof cases[0]);

    for (int i = 0; i < n; ++i) {
        printf("op=%-8s by_code=%-11s by_text=%s\n",
               cases[i].op, classify_by_code(cases[i]), classify_by_text(cases[i]));
    }

    int matches = 0;
    for (int i = 0; i < n; ++i) {
        if (err_is(cases[i], &SENTINEL_NET_TIMEOUT)) {
            ++matches;
        }
    }
    printf("sentinel_err_is_matches=%d\n", matches);
    return 0;
}
