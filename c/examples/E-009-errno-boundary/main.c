#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

/* 边界转换与错误码：库函数（errno 模型）与应用错误码模型是两套体系。
 * 边界层负责把 errno 一次性翻译成应用码；翻译点之后，全链路只认应用码。
 * 与 L2-014（失败后立即保存 errno）衔接：保存是翻译的前置动作。
 * 输出打 errno 的数字值，不依赖 strerror 文案，保证确定性。 */
enum { ERR_OK = 0, ERR_BAD_INPUT = 1, ERR_OUT_OF_RANGE = 2, ERR_MISSING = 3 };

typedef struct {
    int code; /* 应用码：翻译点之后只有它有意义 */
    long value;
    int saved_errno; /* 底层errno留痕：展示与排查用 */
} parse_result_t;

static parse_result_t parse_long(const char* s) {
    parse_result_t r = {ERR_OK, 0, 0};
    char* end = NULL;

    errno = 0;
    r.value = strtol(s, &end, 10);
    r.saved_errno = errno; /* 失败后立即保存，中间不插其他库调用 */

    if (r.saved_errno == ERANGE) {
        r.code = ERR_OUT_OF_RANGE; /* 34 -> 应用码 2 */
        return r;
    }
    if (end == s || *end != '\0') {
        r.code = ERR_BAD_INPUT; /* 非数字 -> 应用码 1 */
        return r;
    }
    return r;
}

/* 边界映射函数：errno -> 应用码。映射表只存在于这一处。 */
static int map_open_errno(int e) {
    switch (e) {
    case ENOENT:
        return ERR_MISSING; /* 2 -> 3：拿不到 */
    case EACCES:
        return ERR_MISSING; /* 13 -> 3：对上层同样是拿不到 */
    default:
        return ERR_BAD_INPUT;
    }
}

int main(void) {
    const char* inputs[] = {"123", "99999999999999999999999", "12abc"};
    for (int i = 0; i < 3; ++i) {
        parse_result_t r = parse_long(inputs[i]);
        printf("input=%-24s app_code=%d errno=%d value=%ld\n", inputs[i], r.code, r.saved_errno,
               r.value);
    }
    printf("map ENOENT=%d -> app_code=%d\n", ENOENT, map_open_errno(ENOENT));
    printf("map EACCES=%d -> app_code=%d\n", EACCES, map_open_errno(EACCES));
    return 0;
}
