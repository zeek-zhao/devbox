/* T-001-oob-double-free 练习现场（有缺陷代码，勿模仿）。
 * 缺陷 1：heap-buffer-overflow —— for 循环写成 i <= n，i == n 时越过 malloc 边界多写 4 字节，
 *          本镜像实测该写踩坏相邻 chunk 的 size 域，裸跑死于下游 free(tag) 的
 *          glibc 断言（症状位置与病因相距甚远）；
 * 缺陷 2：double free —— 同一块 buf 被 free 两次（中间隔一次同尺寸 tag 的 free，
 *          绕过 glibc tcache 只查队头的查重；裸跑因缺陷 1 提前死亡，根本走不到这里）。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    /* 教学点：abort 不会冲刷 stdio 缓冲，管道/重定向（全缓冲）下执行标记会被吞掉
     * （类型②实验实测），先设无缓冲保证标记可见（素材 S-06 的配套动作）。 */
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("run: start\n"); /* 执行标记：证明二进制真的被跑过（素材 S-06） */
    const int n = 10;
    int* buf = malloc((size_t)n * sizeof(int)); /* 40 字节 */
    int* tag = malloc(40);                      /* 与 buf 同尺寸类，缺陷 2 的道具 */
    if (!buf || !tag) {
        printf("run: alloc failed\n");
        return 1;
    }
    memset(tag, 'A', 40);

    for (int i = 0; i <= n; ++i) { /* 缺陷 1：i == n 越界写 4 字节 */
        buf[i] = i;
    }
    int sum = 0;
    for (int i = 0; i < n; ++i) {
        sum += buf[i];
    }
    printf("sum=%d tag=%c\n", sum, tag[0]);

    free(buf);
    free(tag); /* 把 tag 推到同尺寸 tcache 队头，buf 退居第二 */
    free(buf); /* 缺陷 2：double free（gcc -Wall 在此报 -Wuse-after-free，见 WALKTHROUGH） */
    return 0;
}
