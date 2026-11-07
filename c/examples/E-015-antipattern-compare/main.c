#include <stdio.h>

/* 反模式对照：同一个「读配置数字」流程，错误处理好坏两种写法，
 * 可观察结果完全不同。坏版本不崩溃——这正是它危险的地方：
 * 它把失败变成一份静默的假数据，一路流进下游。 */
enum { ERR_OK = 0, ERR_MISSING = 3 };

/* 模拟的配置源：本例固定模拟「打不开」（真实代码里 fopen 返回 NULL + errno=ENOENT，
   转 E-009 的边界映射） */
static int cfg_open(int* ok) {
    *ok = 0;
    return -1;
}

/* 反例：无视打开失败，把「默认值 0」当真数据继续用 */
static int read_number_bad(void) {
    int ok = 1;
    (void)cfg_open(&ok);
    /* 忘了检查 ok：拿 0 当配置值继续走 */
    int value = 0;
    printf("[bad ] value=%d error_reported=0 (失败被吞，拿到假数据)\n", value);
    return value;
}

/* 正解：失败显式上抛，调用方决定策略 */
static int read_number_good(int* out) {
    int ok = 1;
    if (cfg_open(&ok) != 0 || !ok) {
        return ERR_MISSING;
    }
    *out = 42;
    return ERR_OK;
}

int main(void) {
    int bad_value = read_number_bad();
    printf("[bad ] downstream computed=%d (假数据流进下游)\n", bad_value * 2);

    int value = 0;
    int rc = read_number_good(&value);
    if (rc != ERR_OK) {
        printf("[good] value=none error_reported=1 code=%d (失败显式暴露)\n", rc);
        printf("[good] downstream aborted=1 (下游被保护，未拿到假数据)\n");
    }
    return 0;
}
