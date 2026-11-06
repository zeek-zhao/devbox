#include <stdio.h>

/* 上下文附加：错误值除了码与消息，还带一组结构化上下文字段
 * （谁、对什么对象、哪个键、什么值）。消息给人看，上下文给机器查：
 * 告警聚合与日志检索都按字段来，而不是对一句话做模糊匹配。
 * 与 E-004 的「传播与包装」互补：包装改的是消息链，这里挂的是字段表。 */
enum { ERR_OK = 0, ERR_NOT_FOUND = 3, ERR_VALIDATION = 6 };

#define MAX_FIELDS 4

typedef struct {
    const char *key;
    const char *value;
} err_field_t;

typedef struct {
    int code;
    const char *op;      /* 出错的操作 */
    const char *target;  /* 操作对象 */
    err_field_t fields[MAX_FIELDS];
    int nfields;
} error_t;

static error_t err_new(int code, const char *op, const char *target) {
    error_t e;
    e.code = code;
    e.op = op;
    e.target = target;
    e.nfields = 0;
    return e;
}

/* 附加一层上下文；字段表满后新字段不再计入——
 * 附加动作本身不能改变错误身份（不能把错误变成功，也不能改码）。 */
static error_t with_field(error_t e, const char *key, const char *value) {
    if (e.nfields < MAX_FIELDS) {
        e.fields[e.nfields].key = key;
        e.fields[e.nfields].value = value;
        ++e.nfields;
    }
    return e;
}

static error_t load_user(const char *user_id) {
    error_t e = err_new(ERR_NOT_FOUND, "load_user", "users.json");
    return with_field(e, "user_id", user_id);
}

static error_t handle_request(const char *user_id) {
    error_t e = load_user(user_id);
    if (e.code == ERR_OK) {
        return e;
    }
    /* 处理层补上请求级上下文 */
    return with_field(with_field(e, "request", "GET /profile"), "trace", "t-42");
}

static void print_error(const char *label, error_t e) {
    printf("%s code=%d op=%s target=%s", label, e.code, e.op, e.target);
    for (int i = 0; i < e.nfields; ++i) {
        printf(" %s=%s", e.fields[i].key, e.fields[i].value);
    }
    printf("\n");
}

int main(void) {
    print_error("event", handle_request("42"));

    error_t e2 = err_new(ERR_VALIDATION, "parse_profile", "body");
    e2 = with_field(with_field(e2, "field", "age"), "value", "abc");
    print_error("event", e2);
    return 0;
}
