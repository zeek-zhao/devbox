# T-001-oob-double-free · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：`main.c` 的程序「跑着跑着被 abort 杀掉」，dmesg 里一堆 Aborted (core dumped)。
你本地直跑（devbox-cpp 镜像内）：

```bash
gcc -std=c17 -g -O0 main.c -o /tmp/buggy && /tmp/buggy
```

程序打印 `run: start`、`sum=45 tag=A` 后死于：

```text
munmap_chunk(): invalid pointer
rc=134（SIGABRT）
```

报错点指向 `free(tag)` 附近，但 review 发现 `tag` 的分配/使用看起来规规矩矩；
而且有人怀疑代码里还有一处「同一个指针 free 了两次」，可裸跑的栈里根本看不到它。

## 你的任务

1. 先排除「二进制没被真正执行/环境探测失败被误读为代码问题」（素材 S-06 的分支）；
2. 解释为什么 glibc 断言报在无辜的 `tag` 上，把真凶钉到 main.c 的具体行；
3. 找出被这次崩溃掩盖的第二个缺陷，并解释为什么裸跑走不到它；
4. 给出修复 diff 与修复后的验证证据（两个工具都要复查）。

## 可用工具清单（均在 devbox-cpp 镜像内，宿主上没有）

- gcc（`-fsanitize=address` 是编译开关； lesser-known 的 `-fsanitize-recover=address` +
  `ASAN_OPTIONS=halt_on_error=0` 能让 ASan 报完错误继续跑，一份报告收齐所有内存错误）
- valgrind 3.22（`--leak-check=full --error-exitcode=<N>`）
- gdb 15.1（batch 模式：`gdb -batch -ex run -ex bt --args <bin>`；
  ASan 默认不 abort，想让 gdb 接到现场需配 `ASAN_OPTIONS`）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
