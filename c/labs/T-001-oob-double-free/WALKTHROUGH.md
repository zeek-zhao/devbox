---
title: WALKTHROUGH · T-001-oob-double-free（堆越界与双重释放排查）
track: c
lab: T-001-oob-double-free
难度: P2          # P0–P5 刻度：环境齐全、双缺陷、需跨 ASan(含 recover)/valgrind/gdb 三工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-06（「二进制未被执行被误读为代码问题」分支）
verified_env: devbox-cpp:latest（gcc 14.2.0 / valgrind 3.22.0 / gdb 15.1；C 复用 cpp 镜像层，真本 images/lang-images.tsv）
---

# WALKTHROUGH · T-001-oob-double-free

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写；结构沿用 W1 样板
> [cpp/labs/T-001-asan-heap-overflow](../../../cpp/labs/T-001-asan-heap-overflow/WALKTHROUGH.md)。
> 与样板的三处差异：① 场景从「越界 + 泄漏」换成「越界 + double free」——本 lab 的
> `in use at exit: 0 bytes`、`2 allocs, 3 frees` 与样板的 `8 bytes definitely lost` 互为对照；
> ② 新增 ASan recover 模式教学点（`-fsanitize-recover=address` + `halt_on_error=0` 让两个缺陷
> 一份报告齐现形，且实测报错后退出码仍为 0——退出码会撒谎）；③ 裸跑实测不是静默而是
> 死于下游 glibc 断言，且死在缺陷 2 执行之前——崩溃掩盖缺陷（样板 §1 症状三的延伸案例）。
> 所有输出均为 2026-11-06 在 devbox-cpp 容器内真跑所得（地址/PID 已按规范归一化为
> `0xADDR` / `==N==`，无内网信息）。

## 1. 触发症状

在 devbox-cpp 容器内编译并直跑（无任何检测工具）：

```bash
gcc -std=c17 -Wall -g -O0 main.c -o /tmp/buggy-plain
/tmp/buggy-plain; echo "rc=$?"
```

真实输出（类型②实验，2026-11-06，glibc 2.39）：

```text
run: start
sum=45 tag=A
munmap_chunk(): invalid pointer
rc=134
```

**症状一：死于释放阶段的 glibc 断言。** `munmap_chunk(): invalid pointer` + SIGABRT
（rc=134）。断言报在 `free(tag)`（main.c:36）附近，但 tag 的分配/使用本身规规矩矩——
真正病因是 main.c:27 的越界写踩坏了相邻 chunk 的 size 域。**症状与病因相距甚远**，
先去查 tag 的「释放纪律」只会白费劲。

**症状二：编译期已有线索但被无视。** gcc -Wall 对第二个 `free(buf)`（main.c:37）报
`-Wuse-after-free`——这只是警告，构建照样成功，两个缺陷全部带进了二进制。

**症状三：崩溃掩盖缺陷。** 程序死在 main.c:36 之前，`main.c:37` 的 double free
（缺陷 2）从未执行。「崩溃栈里看不到重复释放」不能当「没有重复释放」的证据。

**症状四（教学彩蛋）：stdout 缓冲会吞执行标记。** main.c 起始处有一行
`setvbuf(stdout, NULL, _IONBF, 0)`：删掉它再把本输出重定向到管道/文件（全缓冲），
`run: start`、`sum=45 tag=A` 会因 abort 不冲刷 stdio 缓冲而整体丢失（实测），只剩
`munmap_chunk(): invalid pointer`——看起来像「二进制没被执行过」（素材 S-06 的另一种成因）。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | 重跑一次并看标记行与 `echo $?` | `run: start` / `sum=45 tag=A` 打印 | **无标记行却报错/无错** → 二进制可能根本没被执行，或输出被全缓冲吞掉（§1 症状四，素材 S-06：先排除环境，再谈代码） |
| 2 | `gcc --version \| head -1; valgrind --version; gdb --version \| head -1` | 三个版本号行（14.2.0 / 3.22.0 / 15.1） | `command not found` → 是环境/镜像问题（工具未装，C 复用 devbox-cpp 镜像层），不是代码问题；停，交维护者 |
| 3 | `bash repro.sh 2>&1 \| head -5` | 异常现场：`ERROR: AddressSanitizer: heap-buffer-overflow ...` 且退出非零 | 无 `ERROR:` 行且退出 0 → 越界未被触发，走 §3 决策树左枝 |

三条都只读：不改代码、不改构建、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q1 重跑被测二进制，退出码是否非零且带诊断（glibc 断言 / ERROR: ...）？
├─ 是 → Q2 诊断是什么？
│   ├─ munmap_chunk(): invalid pointer / free(): ... / malloc(): ...（glibc 内存断言）
│   │     → 断言点只是被踩坏的邻居，不是肇事者；直接上 ASan 定位真凶（bash repro.sh）
│   │       不要在报错行的「释放纪律」上打转
│   ├─ ERROR: AddressSanitizer: heap-buffer-overflow
│   │     → 读报告三段：写栈(#0 行号=案发行) / 分配栈(malloc 行号=涉案块) /
│   │       "0x... is located N bytes after M-byte region"（偏移=差多少越多少）
│   │     → 还有没有别的缺陷要查？（崩溃/halt 只能暴露第一个）
│   │        ├─ 要 → Q3
│   │        └─ 不要 → 结束，去 §6 改动后验证
│   ├─ ERROR: AddressSanitizer: attempting double-free
│   │     → 读三段栈：第二次 free 的栈（=非法释放行）/ freed by 栈（=第一次释放行）/
│   │       previously allocated 栈（=分配行）；三行合起来才是完整案情
│   └─ 其他 ASan 类型（heap-use-after-free / stack-* / global-*）
│         → 与本 lab 现场不符（编译器/环境差异），停止并登记 UNVERIFIED 交维护者
└─ 否（退出 0，无报错）→ Q2' 标记行 run: start 打印了吗？
    ├─ 没打印 → 素材 S-06 分支：先确认二进制真的被执行过——
    │     test -x /tmp/buggy-plain && ls -l /tmp/buggy-plain   （文件存在且可执行？）
    │     重定向到管道/文件了吗？→ 先怀疑 stdio 全缓冲吞掉了标记（§1 症状四），
    │     换交互终端或给程序加 setvbuf 重跑；
    │     仍无标记 → 跑的是别的文件/路径错/容器没挂载 → 修环境，不是修代码
    └─ 打印了 → 症状静默、缺陷可能仍在（S-06 的反面：不能因「没报错」就结案）
          → 上工具：bash repro.sh（ASan 构建必报，见 §4.1）

Q3 ASan 默认 halt 只报了第一个错，剩下的缺陷在哪？
├─ 用 recover 模式一次收齐：gcc 加 -fsanitize-recover=address，
│     ASAN_OPTIONS=halt_on_error=0 重跑 → 两个 ERROR 同场（§4.2）；
│     注意此时退出码可能仍是 0，判读看报告内容，不看退出码
└─ recover 模式也不报第二类错 → 症状与现场不符，停止登记 UNVERIFIED
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-cpp 容器真跑）

### 4.1 ASan（repro.sh 内部：`-fsanitize=address` 构建 + 直跑，默认 halt）

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow on address 0xADDR at pc 0xADDR bp 0xADDR sp 0xADDR
WRITE of size 4 at 0xADDR thread T0
    #0 0xADDR in main /w/c/labs/T-001-oob-double-free/main.c:27
    #1 0xADDR in __libc_start_call_main ../sysdeps/nptl/libc_start_call_main.h:58
    #2 0xADDR in __libc_start_main_impl ../csu/libc-start.c:360
0xADDR is located 0 bytes after 40-byte region [0xADDR,0xADDR)
allocated by thread T0 here:
    #0 0xADDR in malloc ../../../../src/libsanitizer/asan/asan_malloc_linux.cpp:69
    #1 0xADDR in main /w/c/labs/T-001-oob-double-free/main.c:18
SUMMARY: AddressSanitizer: heap-buffer-overflow /w/c/labs/T-001-oob-double-free/main.c:27 in main
```

- 第 1 行：诊断类型 = `heap-buffer-overflow`，堆越界而非栈/释放后使用；
- `WRITE of size 4`：是一次 4 字节**写**（`int` 赋值），不是读；
- `#0 ... main.c:27`：**案发行**——`buf[i] = i`，与 `i <= n` 的循环头（26 行）对上；
- `0 bytes after 40-byte region`：写点恰好在 40 字节块（`malloc(10 * sizeof(int))`）末界外
  0 字节处，即第一个越过的元素——**差一错误（off-by-one）的指纹**；
- 分配栈 `malloc ... main.c:18`：涉案块在哪分配的，改哪一行；
- `SUMMARY`：一行结论，可作断言锚点（assert.sh 命中的就是这一族）。

### 4.2 ASan recover 模式（`-fsanitize-recover=address` + `ASAN_OPTIONS=halt_on_error=0`）

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow ... main.c:27    （同 §4.1）
SUMMARY: AddressSanitizer: heap-buffer-overflow .../main.c:27 in main
==N==ERROR: AddressSanitizer: attempting double-free on 0xADDR in thread T0:
    #0 0xADDR in free ../../../../src/libsanitizer/asan/asan_malloc_linux.cpp:52
    #1 0xADDR in main /w/c/labs/T-001-oob-double-free/main.c:37     ← 第二次 free(buf)
freed by thread T0 here:
    #1 0xADDR in main /w/c/labs/T-001-oob-double-free/main.c:35     ← 第一次 free(buf)
previously allocated by thread T0 here:
    #1 0xADDR in main /w/c/labs/T-001-oob-double-free/main.c:18     ← 分配点
SUMMARY: AddressSanitizer: double-free ../../../../src/libsanitizer/asan/asan_malloc_linux.cpp:52 in free
```

- 报了错却**继续跑完**，两个 ERROR 同场：缺陷 1 与缺陷 2 一份报告全钉住；
- double-free 段是三段栈：非法释放行（37）/ 第一次释放行（35）/ 分配行（18）——
  判读时三行合起来看，缺一段案情就不完整；
- **陷阱（实测）**：这份报告对应的进程退出码是 **0**——`halt_on_error=0` 时 ASan 不再
  接管退出码。退出码会撒谎（假设 H4），判读必须落在报告内容上。

### 4.3 valgrind（跑**无工具构建**，`--leak-check=full --error-exitcode=42`）

```text
==N== Invalid write of size 4
==N==    at 0xADDR: main (main.c:27)
==N==  Address 0xADDR is 0 bytes after a block of size 40 alloc'd
==N==    by 0xADDR: main (main.c:18)
==N== Invalid free() / delete / delete[] / realloc()
==N==    at 0xADDR: free (in .../vgpreload_memcheck-amd64-linux.so)
==N==    by 0xADDR: main (main.c:37)
==N==  Address 0xADDR is 0 bytes inside a block of size 40 free'd
==N==    by 0xADDR: main (main.c:35)
==N== HEAP SUMMARY:
==N==     in use at exit: 0 bytes in 0 blocks
==N==   total heap usage: 2 allocs, 3 frees, 80 bytes allocated
==N== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)
```

- `Invalid write ... main.c:27`：与 ASan 互证，同一案发行；
- `Invalid free ... main.c:37` + `block ... free'd ... main.c:35`：缺陷 2 的完整案情——
  释放了一个已经释放过的块，两次 free 的行号都给出；
- `total heap usage: 2 allocs, 3 frees`：2 次分配、3 次 free，多出的那次就是非法的；
- `in use at exit: 0 bytes`：**没有泄漏缺陷**——`2 allocs, 3 frees` 与 `0 bytes in use`
  组合起来的解读是「free 多了」而不是「free 少了」，与样板 lab 的
  `8 bytes definitely lost` 恰好相反，方向别搞反；
- `ERROR SUMMARY: 2 errors` = 1 越界 + 1 非法释放，两缺陷互不掩盖；
- 退出码 42 来自 `--error-exitcode`：valgrind 把「发生过错误」变成可判定的退出码，
  这才是给 CI/断言用的稳定信号。

### 4.4 gdb batch（ASan 构建 + `ASAN_OPTIONS=abort_on_error=1`）

```text
==N==ERROR: AddressSanitizer: heap-buffer-overflow ...
...
Program received signal SIGABRT, Aborted.
...
#11 0xADDR in main () at main.c:27
```

`gdb -batch -ex run -ex bt --args ./buggy-asan` 在故障现场停下，`bt` 的 `main` 帧给出
`main.c:27`，与 ASan 报告互证。必须配 `ASAN_OPTIONS=abort_on_error=1`：ASan 默认直接
`exit 1` 不发 SIGABRT，gdb 根本接不到现场（实测踩过的坑，见 §5 假设 H5）。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：glibc 报 `munmap_chunk(): invalid pointer`，出错的是哪一行？
> （多数人预测：报错的 free 就是坏的——即 free(tag) 用错了。）

**观察**（真实输出，§1 / §4.1）：

```text
munmap_chunk(): invalid pointer          ← 报错点在 free(tag)（main.c:36）附近
ERROR: AddressSanitizer: heap-buffer-overflow ... main.c:27   ← 真凶在 9 行之前的越界写
```

**explain 落差**：越界写踩坏的是**邻居 chunk 的元数据**，被杀的 free 无辜、真正的肇事者
不报错——堆缺陷的「案发地」和「案发现场」经常不是同一处。裸跑结局还取决于堆布局：
同一段代码换一次分配顺序（或在缺陷前多一次 malloc），断言类型/位置就可能变
（样板 lab 的同款教训：静默与崩溃都可能是布局的函数，可靠的只有工具）。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | tag 指针本身坏（未初始化/越权/重复初始化） | ASan 在 free(tag) 处报 `bad-free` 或 tag 分配栈异常 | ASan 在 main.c:27 截停，recover 模式下 free(tag) 无任何诊断 | 排除：tag 只是被邻居踩坏 chunk 头的无辜者 |
| H2 | 裸跑死于 double free（main.c:37） | 程序活到 37 行，崩溃栈里有两次 free(buf) | 死在 main.c:36 的 free(tag)，37 行从未执行；37 行的问题靠 recover 模式（§4.2）才钉住 | 排除：一次崩溃掩盖另一个缺陷 |
| H3 | tcache 查重会拦住第二次 free(buf)，double free 无害 | 第二次 free 被 glibc 拦下并断言 | glibc 2.26+ tcache 确实有查重但**只查队头**：中间隔一次同尺寸 free(tag) 把 buf 顶出队头即绕过（这正是缺陷 2 里 free(tag) 的作用）；recover 模式实测 ASan 报 `attempting double-free` | 排除：有机制 ≠ 覆盖所有场景，别拿「有防护」当「没风险」 |
| H4 | 退出码可信（报了错总会非零） | recover 模式报 2 个 ERROR 应退出非零 | 实测退出码 0（`halt_on_error=0` 时 ASan 不接管退出码） | 排除：退出码语义只在默认 halt 路径成立，判读落到报告内容 |
| H5 | gdb 直接 `run` ASan 构建就能拿到崩溃回溯 | `bt` 出栈帧 | 实际程序直接 `exited with code 01`，`bt` 报 No stack | 排除：ASan 默认不 abort；配 `ASAN_OPTIONS=abort_on_error=1` 后才有 `#11 ... main.c:27` |

## 6. 改动后验证

修复 = 两处：`main.c:26` 的 `i <= n` 改 `i < n`；删掉 `main.c:37` 的第二个 `free(buf);`。
在**副本**上做（别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）：

```bash
cd c/labs/T-001-oob-double-free
sed -e 's/i <= n/i < n/' main.c | grep -v '缺陷 2：double free' > /tmp/fixed.c
gcc -std=c17 -g -O0 -fno-omit-frame-pointer -fsanitize=address /tmp/fixed.c -o /tmp/fixed-asan
/tmp/fixed-asan; echo "rc=$?"
```

健康对照（2026-11-06 修复版真跑）：

```text
run: start
sum=45 tag=A
rc=0
```

ASan 构建退出 0 且**无任何 ERROR 行**（对照 §4.1 的异常输出）。再用 valgrind 复查释放纪律：

```bash
gcc -std=c17 -g -O0 /tmp/fixed.c -o /tmp/fixed-plain && /tmp/fixed-plain; echo "rc=$?"
valgrind --leak-check=full /tmp/fixed-plain 2>&1 | grep -E 'HEAP SUMMARY|in use at exit|total heap usage|All heap blocks|ERROR SUMMARY'
```

真实输出：

```text
run: start
sum=45 tag=A
rc=0            ← 裸跑也回归安静退出（对照 §1 的 SIGABRT）
==N== HEAP SUMMARY:
==N==     in use at exit: 0 bytes in 0 blocks
==N==   total heap usage: 2 allocs, 2 frees, 80 bytes allocated
==N== All heap blocks were freed -- no leaks are possible
==N== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

两个工具都绿 = 修好。注意判据是三个维度：不崩（rc=0）、不泄漏（`All heap blocks were
freed`）、不多释放（`2 allocs, 2 frees`——对照 §4.3 修复前的 `2 allocs, 3 frees`）。
recover 模式也可作第三重复核：修复版 `ASAN_OPTIONS=halt_on_error=0` 重跑无任何 ERROR
（2026-11-06 实测 rc=0）。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `valgrind` / `gdb` / `gcc` 任一 `command not found`（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. ASan 报告类型与本 lab 现场不符（如报 `use-after-free` / `stack-*`），提示编译器或
   镜像版本漂移；
4. 裸跑的 glibc 断言形态大变（如不再报 `munmap_chunk()` 而是别的断言或静默）——布局
   随 glibc 版本漂移，判读口径需维护者重定（§5.1 已预警）；
5. 需要修改 `c/labs/T-001-oob-double-free/` 目录之外的文件才能继续；
6. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-cpp:latest 容器（gcc 14.2.0 / valgrind 3.22.0 /
gdb 15.1，glibc 2.39，Docker on Linux）。`run.sh` 连跑 2 次、`assert.sh` 连跑 2 次，
结论均一致（RUN-PASS 5/5、ASSERT-PASS）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| clang 交叉验证：clang `-fsanitize=address` 同样报 heap-buffer-overflow + double-free | UNVERIFIED | 本轮只跑了镜像默认 gcc 路径 | 下一位维护者在含 clang 的镜像层跑 `CC=clang bash repro.sh` 变体 |
| 裸跑断言形态在其他 glibc 版本下的表现（§5.1 / §7 第 4 条） | UNVERIFIED | 只实测了本镜像 glibc 2.39 的一种布局；未扫其他版本 | 维护者换基础镜像时顺带复跑 §1 三条命令 |
| 删 setvbuf 后「标记行被全缓冲吞掉」（§1 症状四） | UNVERIFIED | 现象在设计阶段实测过，但入库版本已内置 setvbuf，正式 run.sh 路径验不到 | 做变体 lab（教学点单独成题）时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-cpp 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（`0x` 地址 → `0xADDR`、
  `==pid==` → `==N==`），不含内网信息。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」的 lab 化——
  §2 检查 1、§3 的 Q2' 分支（标记行缺失 → 先证二进制真的被执行过/先排除缓冲吞行）
  都是该素材的应用；§1 症状四（abort 吞 stdout）是该素材在 C 场景的新成因，实测登记。
