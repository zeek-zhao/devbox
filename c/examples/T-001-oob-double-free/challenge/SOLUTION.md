# SOLUTION · T-001-oob-double-free（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-cpp 容器真跑（地址/PID 已归一化）。

## 1. 为什么 glibc 断言报在无辜的 tag 上

`main.c:26` 的循环头写成 `i <= n`，`i == n` 时 `buf[i] = i`（main.c:27）越过 40 字节块
末界多写 4 字节。堆上 `tag` 的 chunk 紧跟 `buf`，这 4 字节恰好写进 tag chunk 的 size 域
（原值 0x31 被改写，IS_MMAPPED 位被置上）。于是 `free(tag)`（main.c:36）走进 munmap
分支，被 glibc 当场击杀：

```text
run: start
sum=45 tag=A
munmap_chunk(): invalid pointer
rc=134
```

**症状（free(tag) 崩）与病因（buf 的越界写）相距甚远**——先查 tag 的「释放纪律」只会白费劲。
注意：裸跑死在 main.c:36，**第二个 free(buf)（main.c:37，缺陷 2）从未执行**——一次崩溃
掩盖了另一个缺陷，「栈里看不到重复释放」不代表它不存在。

predict–observe–explain：预测「glibc 断言 = free 用错」→ 观察 36 行的 tag 并无第二次释放，
反倒是它前面 9 行有一次 4 字节越界写 → 解释：堆缺陷的报错点常常是被踩坏的**邻居**，
不是肇事者本身。

## 2. 两个缺陷分别钉在哪（工具取证）

**缺陷 1：堆越界写（ASan，repro.sh 内部）**——`gcc -fsanitize=address` 构建直跑：

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow on address 0xADDR ...
WRITE of size 4 at 0xADDR thread T0
    #0 0xADDR in main .../main.c:27          ← 案发行：buf[i] = i（循环头 i <= n 在 26 行）
0xADDR is located 0 bytes after 40-byte region [0xADDR,0xADDR)
allocated by thread T0 here:
    #1 0xADDR in main .../main.c:18          ← 涉案块：malloc(10 * sizeof(int))
SUMMARY: AddressSanitizer: heap-buffer-overflow .../main.c:27 in main
```

`0 bytes after 40-byte region` = 刚好越过末界的第一个 int，off-by-one 指纹。

**缺陷 2：double free（ASan recover 模式）**——ASan 默认在第一个错误处 halt，想让两个
缺陷一份报告齐现形，用 `-fsanitize-recover=address` 编译 + `ASAN_OPTIONS=halt_on_error=0`：

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow ... main.c:27   ← 缺陷 1
==N==ERROR: AddressSanitizer: attempting double-free on 0xADDR in thread T0:
    #0 0xADDR in free ...
    #1 0xADDR in main .../main.c:37          ← 第二次 free(buf)
freed by thread T0 here:
    #1 0xADDR in main .../main.c:35          ← 第一次 free(buf)
previously allocated by thread T0 here:
    #1 0xADDR in main .../main.c:18
SUMMARY: AddressSanitizer: double-free ... in free
```

**陷阱**：recover 模式报了两个 ERROR，退出码却是 **0**——`halt_on_error=0` 时 ASan 不再
接管退出码。退出码会撒谎，判读必须落在报告内容上。

**valgrind（跑无工具构建）互证**——两个缺陷都报，且能继续跑完全程：

```text
==N== Invalid write of size 4
==N==    at 0xADDR: main (main.c:27)
==N== Invalid free() / delete / delete[] / realloc()
==N==    by 0xADDR: main (main.c:37)          ← 第二次 free(buf)
==N==  Address 0xADDR is 0 bytes inside a block of size 40 free'd
==N==    by 0xADDR: main (main.c:35)          ← 第一次 free(buf)
==N==     in use at exit: 0 bytes in 0 blocks
==N==   total heap usage: 2 allocs, 3 frees, 80 bytes allocated
==N== ERROR SUMMARY: 2 errors from 2 contexts
```

`2 allocs, 3 frees`：3 次 free 里 1 次是非法的——没有泄漏缺陷（与样板 lab 的 leak 场景对照）。

**gdb batch**：`ASAN_OPTIONS=abort_on_error=1` 让 ASan 以 SIGABRT 停下，`bt` 在现场给出
`#11 ... in main () at main.c:27`，与 ASan 报告互证（不配这个选项，ASan 直接 exit 1，
gdb 的 bt 报 No stack）。

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 tag 指针本身坏（越界指针/重复初始化）？→ 若为真，ASan 应在 free(tag) 处报
  `bad-free` 或 tag 的分配栈异常；实际 ASan 根本没走到 free 就在 main.c:27 截停，
  且 recover 模式下 free(tag) 无任何诊断 → 否：tag 只是被邻居踩坏了 chunk 头。
- H2 裸跑死于 double free？→ 若为真，程序应活到 main.c:37；实际死在 main.c:36 的
  free(tag)，37 行从未执行（recover 模式才证明 37 行确实有问题）→ 否：崩溃掩盖缺陷。
- H3 tcache 的查重机制会拦住第二次 free(buf)？→ glibc 2.26+ 的 tcache 确实有 double-free
  查重，但只查队头：中间隔一次同尺寸 free(tag) 把 buf 顶出队头即可绕过（这正是缺陷 2
  代码里 free(tag) 的作用）→ 否：查重存在但不覆盖本场景，别拿「有机制」当「没风险」。
- H4 退出码可信？→ recover 模式实测：两个 ERROR、退出码 0 → 否：ASan 的退出码语义
  只在 halt（默认）路径成立，判读要落到报告内容。

## 4. 修复 diff 与验证

修复 = 两处：`main.c:26` 的 `i <= n` 改 `i < n`；删掉 `main.c:37` 的第二个 `free(buf);`
（副本上做，别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）：

```diff
-    for (int i = 0; i <= n; ++i) {            /* 缺陷 1：i == n 越界写 4 字节 */
+    for (int i = 0; i < n; ++i) {
...
     free(buf);
     free(tag); /* 把 tag 推到同尺寸 tcache 队头，buf 退居第二 */
-    free(buf); /* 缺陷 2：double free（main.c:37） */
```

验证（2026-11-06 修复版真跑，副本 /tmp/fixed.c）：

```text
$ gcc -std=c17 -g -O0 -fsanitize=address /tmp/fixed.c -o /tmp/fixed-asan && /tmp/fixed-asan; echo rc=$?
run: start
sum=45 tag=A
rc=0                                   # 无任何 ERROR 行

$ gcc -std=c17 -g -O0 /tmp/fixed.c -o /tmp/fixed-plain && /tmp/fixed-plain; echo rc=$?
run: start
sum=45 tag=A
rc=0                                   # 裸跑也回归安静退出（对照 §1 的 SIGABRT）

$ valgrind --leak-check=full /tmp/fixed-plain
==N== HEAP SUMMARY:
==N==     in use at exit: 0 bytes in 0 blocks
==N==   total heap usage: 2 allocs, 2 frees, 80 bytes allocated
==N== All heap blocks were freed -- no leaks are possible
==N== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)

$ gcc -std=c17 -g -O0 -fsanitize=address -fsanitize-recover=address /tmp/fixed.c -o /tmp/fixed-rec   && ASAN_OPTIONS=halt_on_error=0:detect_leaks=0 /tmp/fixed-rec; echo rc=$?
run: start
sum=45 tag=A
rc=0                                   # recover 模式也无任何 ERROR
```

注意不是只看「不崩」：`All heap blocks were freed` 是泄漏维度的健康判据，
`ERROR SUMMARY: 0` 是错误维度的，`2 allocs, 2 frees` 说明 free 次数也回归了。两个工具都绿才算修好；把改动落到 lab 的
main.c 前先想清楚——那是缺陷现场，assert.sh 按设计断言「故障在场」，修了它 lab 就废了。
