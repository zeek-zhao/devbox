# T-001-asan-heap-overflow · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：`main.cpp` 的程序「内存曲线只涨不跌」，且安全扫描提示疑似越界。
你本地直跑（devbox-cpp 镜像内）：

```bash
g++ -std=c++20 -g -O0 main.cpp -o /tmp/buggy && /tmp/buggy
```

程序打印 `run: start`、`sum=45 leak_tag=A` 后安静退出，退出码 0，什么也不报。
表面上是「安全扫描误报」，代码 review 一眼也看不出问题；但内存只涨不跌是事实。

## 你的任务

1. 先排除「二进制没被真正执行/环境探测失败被误读为代码问题」（素材 S-06 的分支）；
2. 判断「崩溃隐忧」与「内存只涨不跌」各是哪个缺陷，用工具把它们分别钉到 main.cpp 的具体行；
3. 给出修复 diff 与修复后的验证证据（两个工具都要复查）。

## 可用工具清单（均在 devbox-cpp 镜像内，宿主上没有）

- g++（含 `-fsanitize=address`，编译开关而非独立二进制）
- valgrind 3.22（`--leak-check=full --error-exitcode=<N>`）
- gdb 15.1（batch 模式：`gdb -batch -ex run -ex bt --args <bin>`；
  ASan 默认不 abort，想让 gdb 接到现场需配 `ASAN_OPTIONS`）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
