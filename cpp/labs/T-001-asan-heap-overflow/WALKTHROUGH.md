---
title: WALKTHROUGH · T-001-asan-heap-overflow（ASan 堆越界与泄漏排查）
track: cpp
lab: T-001-asan-heap-overflow
难度: P2          # P0–P5 刻度：环境齐全、双缺陷、需跨 ASan/valgrind/gdb 三工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-06（「二进制未被执行被误读为代码问题」分支）
verified_env: devbox-cpp:latest（g++ 14.2.0 / valgrind 3.22.0 / gdb 15.1）
---

# WALKTHROUGH · T-001-asan-heap-overflow

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写；D1 拍板见
> [docs/73 §11](../../../../docs/73-M11并发执行计划.md)。所有输出均为 2026-11-06 在
> devbox-cpp 容器内真跑所得（地址/PID 已按规范归一化为 `0xADDR` / `==N==`，无内网信息）。

## 1. 触发症状

在 devbox-cpp 容器内编译并直跑（无任何检测工具）：

```bash
g++ -std=c++20 -g -O0 main.cpp -o /tmp/buggy-plain
/tmp/buggy-plain; echo "rc=$?"
```

真实输出（类型②实验，2026-11-06）：

```text
run: start
sum=45 leak_tag=A
rc=0
```

**症状一：静默。** 代码里有两个真实缺陷（`main.cpp:19` 的 `i <= n` 越界写、`main.cpp:14`
的 `leaked` 从不释放），但裸跑退出码 0、无任何报错。肉眼、code review、裸跑回归全都不报。

**症状二：内存曲线只涨不跌（泄漏）。** 每次调用泄漏 8 字节，长跑进程 RSS 缓慢上涨，
无崩溃点可指认。

**症状三（本镜像实测，教学彩蛋）：裸跑结局取决于 glibc 堆布局，症状不可靠。**
同一段代码只要改动一次堆分配顺序——比如在 `new[]` 之前多打一行输出（早期版本的
`main.cpp` 就是这样）——裸跑就直接死：

```text
Fatal glibc error: malloc.c:2599 (sysmalloc): assertion failed: (old_top == initial_top (av) && old_size == 0) || ...
```

死因是 4 字节越界写踩坏相邻 chunk 元数据后，下游某次 `malloc` 触发断言——**报错位置与
病因相距甚远**。所以「裸跑不崩」绝不能当「没有越界」的证据。

## 2. 前 60 秒三条只读检查（成本从低到低高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | 重跑一次并看 `echo $?` 与标记行 | `run: start` 打印、退出码符合预期 | **无 `run: start` 却报了错/无错** → 二进制可能根本没被执行（素材 S-06：先排除环境，再谈代码） |
| 2 | `g++ --version \| head -1; valgrind --version; gdb --version \| head -1` | 三个版本号行（14.2.0 / 3.22.0 / 15.1） | `command not found` → 是环境/镜像问题（工具未装），不是代码问题；停，交维护者 |
| 3 | `bash repro.sh 2>&1 \| head -5` | 异常现场：`ERROR: AddressSanitizer: heap-buffer-overflow ...` 且退出非零 | 无 `ERROR:` 行且退出 0 → 越界未被触发，走 §3 决策树左枝 |

三条都只读：不改代码、不改构建、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q1 重跑被测二进制，退出码是否非零且带诊断头（ERROR: ... / Fatal ...）？
├─ 是 → Q2 诊断头是什么？
│   ├─ ERROR: AddressSanitizer: heap-buffer-overflow
│   │     → 读报告三段：写栈(#0 行号=案发行) / 分配栈(operator new[] 行号=涉案块) /
│   │       "0x... is located N bytes after M-byte region"（偏移=差多少越多少）
│   │     → 还有泄漏要查吗？
│   │        ├─ 要 → Q3
│   │        └─ 不要 → 结束，去 §6 改动后验证
│   ├─ ERROR: AddressSanitizer: heap-use-after-free / stack-* / 其他类型
│   │     → 与本 lab 现场不符（编译器/环境差异），停止并登记 UNVERIFIED 交维护者
│   └─ Fatal glibc error: malloc.c ...
│         → 裸跑被踩坏堆元数据的下游症状；症状不可靠，直接上 ASan 定位真凶（repro.sh）
└─ 否（退出 0，无报错）→ Q2' 标记行 run: start 打印了吗？
    ├─ 没打印 → 素材 S-06 分支：先确认二进制真的被执行过——
    │     test -x /tmp/buggy-plain && ls -l /tmp/buggy-plain   （文件存在且可执行？）
    │     再在程序入口加执行标记（本 lab 已内置 run: start）重跑；
    │     仍无标记 → 跑的是别的文件/路径错/容器没挂载 → 修环境，不是修代码
    └─ 打印了 → 症状静默、缺陷仍在（S-06 的反面：不能因"没报错"就结案）
          → 上工具：bash repro.sh（ASan 构建必报，见 §4）

Q3 ASan 报了越界但没报泄漏，泄漏在哪？
├─ ASan 在第一个内存错误处立即中止，进程走不到 exit，LeakSanitizer 没机会跑
│     → 用 valgrind 跑【无工具构建】补查泄漏（与 ASan 二选一跑，勿叠加，
│       cpp/docs/工具指南.md §4）→ 读 "definitely lost" 行（§4 下半）
└─ valgrind 也不报泄漏 → 症状与现场不符，停止登记 UNVERIFIED
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-cpp 容器真跑）

### 4.1 ASan（repro.sh 内部：`-fsanitize=address` 构建 + 直跑）

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow on address 0xADDR at pc 0xADDR bp 0xADDR sp 0xADDR
WRITE of size 4 at 0xADDR thread T0
    #0 0xADDR in main /work/cpp/labs/T-001-asan-heap-overflow/main.cpp:20
    #1 0xADDR in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58
    #2 0xADDR in __libc_start_main_impl ../csu/libc-start.c:360
0xADDR is located 0 bytes after 40-byte region [0xADDR,0xADDR)
allocated by thread T0 here:
    #0 0xADDR in operator new[](unsigned long) ../../../../src/libsanitizer/asan/asan_new_delete.cpp:98
    #1 0xADDR in main /work/cpp/labs/T-001-asan-heap-overflow/main.cpp:18
    ...
SUMMARY: AddressSanitizer: heap-buffer-overflow /work/cpp/labs/T-001-asan-heap-overflow/main.cpp:20 in main
```

- 第 1 行：诊断类型 = `heap-buffer-overflow`，堆越界而非栈/释放后使用；
- `WRITE of size 4`：是一次 4 字节**写**（`int` 赋值），不是读；
- `#0 ... main.cpp:20`：**案发行**——`buf[i] = i`，与 `i <= n` 的循环头（19 行）对上；
- `0 bytes after 40-byte region`：写点恰好在 40 字节块（`new int[10]`）末界外 0 字节处，
  即第一个越过的元素——**差一错误（off-by-one）的指纹**；
- 分配栈 `operator new[] ... main.cpp:18`：涉案块在哪分配的，改哪一行；
- `SUMMARY`：一行结论，可作断言锚点（assert.sh 命中的就是这一族）。

### 4.2 valgrind（跑**无工具构建**，`--leak-check=full`）

```text
==N== Invalid write of size 4
==N==    at 0xADDR: main (main.cpp:20)
==N==  Address 0xADDR is 0 bytes after a block of size 40 alloc'd
==N==    by 0xADDR: main (main.cpp:18)
==N==
==N== HEAP SUMMARY:
==N==     in use at exit: 8 bytes in 1 blocks
==N==   total heap usage: 4 allocs, 3 frees, 77,872 bytes allocated
==N==
==N== 8 bytes in 1 blocks are definitely lost in loss record 1 of 1
==N==    by 0xADDR: main (main.cpp:14)
==N== LEAK SUMMARY:
==N==    definitely lost: 8 bytes in 1 blocks
==N== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)
```

- `Invalid write of size 4 ... main.cpp:20`：与 ASan 互证，同一案发行；
- `total heap usage: 4 allocs, 3 frees`：4 次分配（leaked、buf、iostream 内部两块）
  只 free 3 次 → 差的那次就是泄漏；
- `8 bytes in 1 blocks are definitely lost ... main.cpp:14`：泄漏块精确指到
  `char* leaked = new char[leak_size]`，8 字节 = `leak_size` 默认值，**块数 1** 说明是单块整丢
  （不是部分丢失的链表结构）；
- `ERROR SUMMARY: 2 errors` = 1 个越界 + 1 个泄漏，两个缺陷各自独立、互不掩盖：
  ASan 只能给你第一个（它在越界处就中止了），泄漏必须靠 valgrind（或修好越界后再跑
  LeakSanitizer）。

### 4.3 gdb batch（ASan 构建 + `ASAN_OPTIONS=abort_on_error=1`）

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow ...
...
#11 0xADDR in main (argc=1, argv=0xADDR) at main.cpp:20
```

`gdb -batch -ex run -ex bt --args ./buggy-asan` 在故障现场停下，`bt` 的 `main` 帧给出
`main.cpp:20`，与 ASan 报告互证。注意必须配 `ASAN_OPTIONS=abort_on_error=1`：ASan 默认
直接 `exit 1` 不发 SIGABRT，gdb 根本接不到现场（实测踩过的坑，见 §5 假设 H4）。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：带着堆越界的程序，直接跑会发生什么？退出码是多少？
> （多数人预测：崩溃 / 非零退出 / 至少有报错。）

**观察**（真实输出）：

```text
run: start
sum=45 leak_tag=A
rc=0
```

**explain 落差**：4 字节越界只写进了 `new int[10]` 相邻的堆元数据/空闲区，glibc 2.39 的
当前布局下没有立即可见的后果——程序把错误吞了。裸跑的「没崩」是**运气的函数**：
早期版本在 `new[]` 前多打一行输出（多一次分配），同一份缺陷代码就死于
`Fatal glibc error: malloc.c:2599`（§1 症状三）。两次实测合起来的结论：**裸跑结局由堆
布局决定，症状不可靠；可靠的只有工具**。这也是 assert.sh 不对裸跑行为做逐字断言、
只对工具诊断行做断言的原因。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | 越界发生在**栈**上（数组是局部的） | `stack-buffer-overflow`，写栈里没有堆分配帧 | `heap-buffer-overflow` + 分配栈 `operator new[] ... main.cpp:18` | 排除：`buf` 是堆块 |
| H2 | 是 **use-after-free**（先 delete 再用） | 报告类型 `heap-use-after-free`，报告里出现 `freed by` 段 | 类型是 `heap-buffer-overflow`，只有 `allocated by` 段，且 `0 bytes after 40-byte region` | 排除：块还活着，只是踩过界 |
| H3 | 泄漏的是 `buf`（40 字节）或 iostream 内部缓冲 | 泄漏记录 `40 bytes` 或大量 `still reachable` | `8 bytes in 1 blocks ... main.cpp:14`，`4 allocs, 3 frees` | 排除：`buf` 在 27 行已释放，丢的是 14 行的 `leaked` |
| H4 | gdb 直接 `run` ASan 构建就能拿到崩溃回溯 | `bt` 出栈帧 | 实际程序直接 `exited with code 01`，`bt` 报 `No stack` | 排除：ASan 默认不 abort；配 `ASAN_OPTIONS=abort_on_error=1` 后才有 `#11 ... main.cpp:20` |

## 6. 改动后验证

修复 = 两处：`main.cpp:19` 的 `i <= n` 改 `i < n`；`main.cpp:27` 后补 `delete[] leaked;`。
在**副本**上做（别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）：

```bash
cd cpp/labs/T-001-asan-heap-overflow
sed -e 's/i <= n/i < n/' main.cpp > /tmp/fixed.cpp
# 再手工在 /tmp/fixed.cpp 的 delete[] buf; 后补一行 delete[] leaked;
g++ -std=c++20 -g -O0 -fno-omit-frame-pointer -fsanitize=address /tmp/fixed.cpp -o /tmp/fixed-asan
/tmp/fixed-asan; echo "rc=$?"
```

健康对照（2026-11-06 修复版真跑）：

```text
run: start
sum=45 leak_tag=A
rc=0
```

ASan 构建退出 0 且**无任何 ERROR 行**（对照 §4.1 的异常输出）。再用 valgrind 复查泄漏：

```bash
g++ -std=c++20 -g -O0 /tmp/fixed.cpp -o /tmp/fixed-plain
valgrind --leak-check=full /tmp/fixed-plain 2>&1 | grep -E 'HEAP SUMMARY|in use at exit|All heap blocks|ERROR SUMMARY'
```

真实输出：

```text
==N== HEAP SUMMARY:
==N==     in use at exit: 0 bytes in 0 blocks
==N== All heap blocks were freed -- no leaks are possible
==N== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

两个工具都绿 = 修好。注意不是只看「不崩」：`All heap blocks were freed` 是泄漏维度的
健康判据，`ERROR SUMMARY: 0` 是错误维度的。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `valgrind` / `gdb` / `g++` 任一 `command not found`（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. ASan 报告类型与本 lab 现场不符（如报 `use-after-free` / `stack-*`），提示编译器或
   镜像版本漂移；
4. 需要修改 `cpp/labs/T-001-asan-heap-overflow/` 目录之外的文件才能继续；
5. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-cpp:latest 容器（g++ 14.2.0 / valgrind 3.22.0 /
gdb 15.1，Docker on Linux）。`run.sh` 连跑 2 次、`assert.sh` 连跑 2 次，结论均一致
（RUN-PASS 4/4、ASSERT-PASS）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| g++ 交叉验证：clang++ `-fsanitize=address` 同样报 heap-buffer-overflow | UNVERIFIED | 本轮只跑了镜像默认 g++ 路径 | 下一位维护者在含 clang++ 的镜像层跑 `run.sh` 变体 |
| 裸跑在其他 glibc 版本下的结局（§1 症状三） | UNVERIFIED | 只实测了本镜像 glibc 2.39 的两种布局（改/不改分配顺序）；未扫其他版本 | 维护者换基础镜像时顺带复跑 §1 三条命令 |
| LeakSanitizer 独立跑（修越界后正常退出的 ASan 构建上 `detect_leaks=1`） | UNVERIFIED | 本 lab 用 valgrind 承担泄漏维度（ASan 构建在越界处中止，LSan 无机会运行） | 做变体 lab 时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-cpp 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（`0x` 地址 → `0xADDR`、
  `==pid==` → `==N==`），不含内网信息。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」的 lab 化——
  §2 检查 1、§3 的 Q2' 分支（标记行缺失 → 先证二进制真的被执行过）与
  §5.1 POE 点（裸跑沉默 ≠ 没有缺陷）都是该素材的正面/反面应用。
