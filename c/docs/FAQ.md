---
track: c
guide: G5
dimensions: [D2, D5, D8]
level: P2
status: draft
links: [知识点清单.md, 用例编写规范.md, 开发指南.md, 工具指南.md]
examples: [L0-hello, L1-020-malloc-free, L2-006-asan-bounds, L2-009-leak-detection, L2-010-strict-warnings]
---

# C FAQ（G5）

> 高频短问答，按主题分组，每条 10 秒内对号：结论 → 一步命令 → 详见 G2/G4。
> 卡在一个具体故障上要排查路径的，去 [开发指南.md](开发指南.md) §3 的失败顺序表；
> 查命令参数去 [工具指南.md](工具指南.md)。版本号只引用 `images/versions.env` 变量。

## 上手与环境

### Q: C 轨道用哪个镜像？是不是要单独装一套 C 环境？

A: 不用。C 复用 `devbox-cpp` 镜像层，与 C++ 同一套 gcc/clang 工具链，映射真本是
`images/lang-images.tsv`。核验：`TAG=latest scripts/run-example.sh c L0-hello`，
输出 `PASS` 即通路正常。详见 [开发指南.md](开发指南.md) §1。

### Q: 镜像 tag 写 latest 还是别的？CI 传的 IMAGE_TAG 是什么关系？

A: 同一个值的两个名字。runner 取值顺序 `TAG` → `IMAGE_TAG` → `local`：CI 传
`IMAGE_TAG`，本地传 `TAG`。命令统一 `TAG=latest scripts/run-example.sh c <ID>`；
本地已有自建镜像时换 `TAG=local`。禁止把 tag 写死进文档或脚本。
详见 [开发指南.md](开发指南.md) §1。

### Q: 工具链是什么版本？文档里怎么没写数字？

A: 版本唯一真本是 `images/versions.env`：gcc 用 `${GCC_MAJOR}`，clang 与
clang-format 用 `${CLANG_MAJOR}` / `${CLANG_FORMAT_MAJOR}`。指南写变量名不写字面量，
改版本时文档不会集体过期。实测核验命令见 [工具指南.md](工具指南.md) §1 全景表。

## 跑用例

### Q: 报 NO-RUNNER 或 MISSING 是什么意思？

A: 三文件契约没满足：用例目录下缺 `run.sh` 报 `NO-RUNNER`，目录本身不存在报
`MISSING`。先对照 [知识点清单.md](知识点清单.md) 核对 ID 拼写，再确认 `run.sh`
存在且可执行。用例写法详见 [用例编写规范.md](用例编写规范.md)。

### Q: 输出和 expected.txt 对不上（MISMATCH）怎么办？

A: 先分辨是「改坏了」还是「故意改了行为」。加 `--keep` 进容器手工跑 `run.sh`
diff 两边输出；确认是预期变更后按规范更新 `expected.txt`（`--update` 仅限新写用例）。
一步复现：`TAG=latest scripts/run-example.sh c <ID> --keep`。
详见 [开发指南.md](开发指南.md) §3。

### Q: 78 个用例怎么一把全跑？

A: `TAG=latest scripts/run-example.sh c --all`，与 CI 的 examples job 同入口；
只看清单用 `--list`。单例跑法与失败顺序见 [开发指南.md](开发指南.md) §3。

## 工具与调试

### Q: 编译警告开到什么程度算本仓库的基线？

A: `-std=c17 -Wall -Wextra -Werror` 一起用是刻意基线（见 `L0-hello/run.sh`）：
C 的很多坑（隐式声明、有符号/无符号比较）只有开警告才暴露，`-Werror` 保证它们被当回事。
更严口径与静态分析见 `L2-010-strict-warnings`、`L2-011-gcc-analyzer`；
参数速查见 [工具指南.md](工具指南.md) §2。

### Q: 怀疑有内存泄漏，先用 ASan 还是 valgrind？

A: 日常首选 ASan：编译加 `-fsanitize=address`，快且有行号，泄漏配
`ASAN_OPTIONS=detect_leaks=1`（对应 `L1-020-malloc-free`、`L2-009-leak-detection`）；
查不能重编的二进制才用 valgrind。两者二选一，不叠加。
详见 [工具指南.md](工具指南.md) §2/§3。

### Q: 程序崩溃了，怎么最快拿到调用栈？

A: 编译带 `-g`，用 gdb 批处理一步出回溯：`gdb -batch -ex run -ex bt ./程序`，
适合直接进 CI 日志（对应 `L2-008-gdb-batch-backtrace`）。想交互式断点，用 runner
`--keep` 保留容器后 `docker exec` 进去。详见 [工具指南.md](工具指南.md) §2。

### Q: 本地格式化通过，CI 的 fmt-check 却红了？

A: 多半是 clang-format 版本失配——`${CLANG_FORMAT_MAJOR}` 必须与 `${CLANG_MAJOR}`
同步，本地手调 clang-format 容易版本漂移。改走统一入口：
`bash scripts/fmt.sh --check --lang c`（容器内跑，版本来自真本）。
详见 [工具指南.md](工具指南.md) §4。

## 查不到时去哪查

1. **本仓库已知限制**：`docs/ROADMAP.md` 的 `KI-*` 段（如 `:latest` 标签并发污染
   `KI-08`、非 root 运行 `KI-07`），已定案的不重复建 issue。
2. **仓库级指南**：`docs/60-AI工作指南.md`（门禁、真本、提交身份）与
   `docs/01-镜像体系.md`（分层与 tag 口径）。
3. **上游文档**：gcc/clang 官方手册、gdb/valgrind 官方文档——本指南只写本工程口径，
   语言与工具的通用语义以上游为准，且不在此复述语法（语法归 L1 用例）。
4. **issue 搜索**：先搜仓库 issue 再提新单；`docs/40-问题清单.md` 的 `Q-*` 编号
   已定案的结论也在里面。
