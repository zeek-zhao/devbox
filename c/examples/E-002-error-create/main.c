#include <stdio.h>

/* 创建与抛出（C 口径）：C 没有 throw，一次失败被「装进一个显式的
 * 错误值并 return」，这就是 C 里的创建与抛出。
 * 纪律：
 *   - 错误值三要素齐全：码（身份）、what（稳定标识，供精确匹配）、
 *     detail（人读上下文，只展示不匹配）；
 *   - code 为 0 表示成功，成功路径返回统一的 ERR_NONE；
 *   - 错误值一经构造不再改写，调用方决定继续传播还是就地处理。 */
typedef struct {
    int code;
    const char *what;
    const char *detail;
} error_t;

static const error_t ERR_NONE = { 0, "ok", "" };

/* 「抛出」= return 一个填好的错误值。 */
static error_t validate_age(int age) {
    if (age < 0) {
        error_t e = { 1, "age_negative", "age must be >= 0" };
        return e;
    }
    if (age > 150) {
        error_t e = { 2, "age_unrealistic", "age must be <= 150" };
        return e;
    }
    return ERR_NONE;
}

static error_t validate_name(const char *name) {
    if (name == NULL || name[0] == '\0') {
        error_t e = { 3, "name_empty", "name must be non-empty" };
        return e;
    }
    return ERR_NONE;
}

static void report(const char *input, error_t e) {
    if (e.code == 0) {
        printf("input=%s result=ok\n", input);
    } else {
        printf("input=%s result=error code=%d what=%s detail=\"%s\"\n",
               input, e.code, e.what, e.detail);
    }
}

int main(void) {
    report("age=30", validate_age(30));
    report("age=-7", validate_age(-7));
    report("age=999", validate_age(999));
    report("name=\"\"", validate_name(""));
    return 0;
}
