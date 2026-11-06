#include <stdio.h>
#include <stdlib.h>

/* goto cleanup：一个函数申请多个资源时，错误路径从任意深度一跳到
 * 统一出口，按申请的逆序释放。C 没有析构函数/defer，
 * 这是唯一能保证「每条错误路径都走完释放序列」的惯用法。
 * 纪律：所有变量先初始化为「未持有」；出口只释放已持有的；
 *       释放后立刻置空/复位，防双重释放。 */
enum { ERR_OK = 0, ERR_NO_MEM = 5, ERR_LOCKED = 8 };

static int open_session(int fail_at_lock) {
    int rc = ERR_OK;
    char *buf = NULL;    /* 先统一置「未持有」 */
    int handle = -1;
    int locked = 0;

    buf = malloc(64);
    if (buf == NULL) {
        rc = ERR_NO_MEM;
        goto cleanup;
    }
    printf("acquire buf\n");

    handle = 7;          /* 模拟打开设备句柄 */
    printf("acquire handle\n");

    if (fail_at_lock) {
        rc = ERR_LOCKED; /* 模拟加锁失败 */
        printf("fail at lock\n");
        goto cleanup;
    }
    locked = 1;
    printf("acquire lock\n");
    printf("session ready\n");

cleanup:
    /* 统一出口：按申请逆序释放，只释放已持有的 */
    if (locked) {
        printf("release lock\n");
        locked = 0;
    }
    if (handle >= 0) {
        printf("release handle\n");
        handle = -1;
    }
    if (buf != NULL) {
        free(buf);
        printf("release buf\n");
        buf = NULL;
    }
    printf("open_session rc=%d\n", rc);
    return rc;
}

int main(void) {
    printf("-- success path --\n");
    open_session(0);
    printf("-- failure path --\n");
    open_session(1);
    return 0;
}
