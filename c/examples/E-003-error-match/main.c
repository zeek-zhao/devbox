#include <stdio.h>

/* 捕获与精确匹配：调用方「捕获」一个错误值后，先精确匹配有既定策略的码，
 * 剩下的统一落进兜底分支。两条纪律：
 *   - 匹配永远用码（switch/==），不用消息文本——文本会改，码是身份；
 *   - 必须有 default 兜底——新增码落进兜底会显式暴露为 escalate，
 *     而不是被当成某个已知码处理。 */
enum { ERR_OK = 0, ERR_NOT_FOUND = 3, ERR_TIMEOUT = 4, ERR_NO_MEMORY = 5 };

typedef struct { int code; const char *what; } error_t;

static error_t fetch_record(int simulate) {
    switch (simulate) {
        case 1: { error_t e = { ERR_NOT_FOUND, "record missing" };    return e; }
        case 2: { error_t e = { ERR_TIMEOUT,   "backend slow" };      return e; }
        case 3: { error_t e = { ERR_NO_MEMORY, "cache alloc failed" }; return e; }
    }
    { error_t ok = { ERR_OK, "record 42" }; return ok; }
}

static void handle(int simulate) {
    error_t e = fetch_record(simulate);
    if (e.code == ERR_OK) {
        printf("sim=%d matched=NONE outcome=ok\n", simulate);
        return;
    }
    switch (e.code) {
        case ERR_NOT_FOUND:
            printf("sim=%d matched=EXACT code=%d outcome=create-default-record\n",
                   simulate, e.code);
            break;
        case ERR_TIMEOUT:
            printf("sim=%d matched=EXACT code=%d outcome=retry-later\n",
                   simulate, e.code);
            break;
        default:
            printf("sim=%d matched=FALLBACK code=%d outcome=escalate\n",
                   simulate, e.code);
            break;
    }
}

int main(void) {
    for (int s = 0; s <= 3; ++s) {
        handle(s);
    }
    return 0;
}
