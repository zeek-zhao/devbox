#include <stdio.h>

/* 错误分类与类型体系：先定义一套封闭的错误码枚举，再给每个码一个
 * 唯一的稳定分类。分类（而不是具体码）决定处理策略：
 *   USAGE       —— 调用方 bug，修调用，不重试；
 *   ENVIRONMENT —— 外部状态，可重试或上报；
 *   INTERNAL    —— 程序前提被破坏，快速失败。
 * 没有这套体系时，同一个码在不同调用点会被随意解读。 */
typedef enum {
    ERR_OK = 0,
    ERR_INVALID,   /* 参数不合法 */
    ERR_RANGE,     /* 数值超出可接受区间 */
    ERR_NOT_FOUND, /* 目标不存在 */
    ERR_TIMEOUT,   /* 等待超时 */
    ERR_NO_MEMORY  /* 资源耗尽 */
} err_code_t;

typedef enum { CAT_OK = 0, CAT_USAGE, CAT_ENVIRONMENT, CAT_INTERNAL } err_category_t;

/* 每个码一行，保证「码 → 名字」映射完备；switch 覆盖全部枚举值，
 * 新增码漏写分支时 -Wswitch 直接编译报错。 */
const char* err_name(err_code_t c) {
    switch (c) {
    case ERR_OK:
        return "OK";
    case ERR_INVALID:
        return "INVALID";
    case ERR_RANGE:
        return "RANGE";
    case ERR_NOT_FOUND:
        return "NOT_FOUND";
    case ERR_TIMEOUT:
        return "TIMEOUT";
    case ERR_NO_MEMORY:
        return "NO_MEMORY";
    }
    return "UNKNOWN";
}

/* 「码 → 类别」唯一映射：这是错误体系的锚。 */
err_category_t classify(err_code_t c) {
    switch (c) {
    case ERR_OK:
        return CAT_OK;
    case ERR_INVALID:
    case ERR_RANGE:
        return CAT_USAGE;
    case ERR_NOT_FOUND:
    case ERR_TIMEOUT:
        return CAT_ENVIRONMENT;
    case ERR_NO_MEMORY:
        return CAT_INTERNAL;
    }
    return CAT_INTERNAL;
}

const char* cat_name(err_category_t t) {
    switch (t) {
    case CAT_OK:
        return "OK";
    case CAT_USAGE:
        return "USAGE";
    case CAT_ENVIRONMENT:
        return "ENVIRONMENT";
    case CAT_INTERNAL:
        return "INTERNAL";
    }
    return "?";
}

int main(void) {
    const err_code_t codes[] = {ERR_OK,        ERR_INVALID, ERR_RANGE,
                                ERR_NOT_FOUND, ERR_TIMEOUT, ERR_NO_MEMORY};
    const int n = (int)(sizeof codes / sizeof codes[0]);

    for (int i = 0; i < n; ++i) {
        printf("code=%d name=%s category=%s\n", (int)codes[i], err_name(codes[i]),
               cat_name(classify(codes[i])));
    }

    int usage = 0, env = 0, internal = 0;
    for (int i = 0; i < n; ++i) {
        switch (classify(codes[i])) {
        case CAT_OK:
            break;
        case CAT_USAGE:
            ++usage;
            break;
        case CAT_ENVIRONMENT:
            ++env;
            break;
        case CAT_INTERNAL:
            ++internal;
            break;
        }
    }
    printf("taxonomy codes=%d usage=%d environment=%d internal=%d\n", n, usage, env, internal);
    return 0;
}
