# SOLUTION · T-001-asan-heap-overflow（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-cpp 容器真跑（地址/PID 已归一化）。

## 1. 为什么裸跑是沉默的？缺陷在不在？

在（两个都真实存在）。裸跑沉默只说明 glibc 当前堆布局吞下了那 4 字节越界写，不说明没缺陷：

```text
run: start
sum=45 leak_tag=A
rc=0
```

predict–observe–explain：预测「会崩/非零退出」→ 观察退出码 0 → 解释：越界写落在相邻
chunk 的空闲处，无立即可见后果。注意这不可靠——同一段代码只要改一次堆分配顺序
（如 `new[]` 前多打一行输出），裸跑就死于 `Fatal glibc error: malloc.c:2599`（实测）。
结论：裸跑结局是布局的函数，证据必须来自工具。

先排除 S-06 分支：标记行 `run: start` 打印了 → 二进制真的被执行过 → 可以谈代码。

## 2. 两个缺陷分别钉在哪

**缺陷 1：堆越界写（ASan）**——`g++ -fsanitize=address` 构建直跑：

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow on address 0xADDR ...
WRITE of size 4 at 0xADDR thread T0
    #0 0xADDR in main .../main.cpp:20          ← 案发行：buf[i] = i（循环头 i <= n 在 19 行）
0xADDR is located 0 bytes after 40-byte region [0xADDR,0xADDR)
allocated by thread T0 here:
    #1 0xADDR in main .../main.cpp:18          ← 涉案块：new int[10]
```

`0 bytes after 40-byte region` = 刚好越过末界的第一个 int，off-by-one 指纹。

**缺陷 2：内存泄漏（valgrind，跑无工具构建）**——ASan 在越界处即中止、走不到 exit，
泄漏要用 valgrind 补查（两者二选一，勿叠加）：

```text
==N== Invalid write of size 4
==N==    at 0xADDR: main (main.cpp:20)
==N== 8 bytes in 1 blocks are definitely lost in loss record 1 of 1
==N==    by 0xADDR: main (main.cpp:14)         ← 泄漏块：char* leaked = new char[leak_size]
==N==    definitely lost: 8 bytes in 1 blocks
==N== ERROR SUMMARY: 2 errors from 2 contexts
```

「内存只涨不跌」= `main.cpp:14` 的 `leaked` 从不释放；「崩溃隐忧」= `main.cpp:19/20`
的 `i <= n` 越界写。两个独立缺陷。

（附：`gdb -batch -ex run -ex bt` 想接到现场需 `ASAN_OPTIONS=abort_on_error=1`，
否则 ASan 默认直接 exit 1，gdb 的 bt 报 No stack。）

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 栈越界？→ ASan 应报 `stack-buffer-overflow`；实际 `heap-buffer-overflow` +
  分配栈 `operator new[]` → 否。
- H2 use-after-free？→ 应报 `heap-use-after-free` 且有 `freed by` 段；实际只有
  `allocated by` 段 → 否。
- H3 泄漏的是 buf（40 字节）？→ 应见 40 字节丢失；实际 `8 bytes ... main.cpp:14`，
  且 `4 allocs, 3 frees` 表明 buf 已释放 → 否。

## 4. 修复 diff 与验证

```diff
-    for (int i = 0; i <= n; ++i) {            // 缺陷 1：i == n 越界写 4 字节
+    for (int i = 0; i < n; ++i) {
...
-    delete[] buf;                             // leaked 故意不释放
+    delete[] buf;
+    delete[] leaked;
```

验证（2026-11-06 修复版真跑）：

```text
$ /tmp/fixed-asan; echo rc=$?          # ASan 构建
run: start
sum=45 leak_tag=A
rc=0                                   # 无任何 ERROR 行

$ valgrind --leak-check=full /tmp/fixed-plain
==N==     in use at exit: 0 bytes in 0 blocks
==N== All heap blocks were freed -- no leaks are possible
==N== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

两个工具都绿才算修好；把改动落到 lab 的 main.cpp 前先想清楚——那是缺陷现场，
assert.sh 按设计断言「故障在场」，修了它 lab 就废了。
