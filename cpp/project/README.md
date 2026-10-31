# C++ 文本索引器

高性能文本索引器：用 mmap 读文件、建立倒排索引、按词查询，并提供基准计时。

从 `cpp/project/` 执行以下命令：

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j
./build/devbox-cpp-project /path/to/file.txt alpha
ctest --test-dir build --output-on-failure
./build/bench_index /path/to/file.txt alpha
```

## 分词规则

连续的 ASCII 英文字母和数字组成一个词；空白、标点及其他字节都是分隔符。索引和查询都会把 ASCII 大写字母转成小写。查询参数应是一个词。同一行中的重复词只会产生一个行号；输出保留原始行内容，行号从 1 开始。

## 用了哪些知识点

- 使用 POSIX `mmap` 映射输入文件，避免用 `ifstream` 全量读取。
- 扫描文本建立“词 → 行号列表”的倒排索引，并按行号顺序查询。
- 用 RAII 管理映射和文件描述符，并在索引构建完成后释放映射。
- 使用 CMake、断言测试和 stderr 基准计时。

完整覆盖表见 [COVERAGE.md](COVERAGE.md)：77 个用例均已接入，包含 23 个模式的逐项类/函数映射。

## 构建、依赖与工程检查

需要 CMake 3.28+、支持 C++20 的编译器、POSIX mmap/pthreads；仓库的
`ghcr.io/zeek-zhao/devbox-cpp:local` 已提供这些工具。唯一平台依赖通过
`find_package(Threads)` 声明并随安装包传播，不下载外部库。所有项目目标启用
`-Wall -Wextra -Wpedantic -Werror`，测试额外 `-UNDEBUG`，Release 不会关闭断言。

```bash
# 干净构建、测试、安装、独立 find_package 消费者、TGZ 打包
bash tests/check-build.sh

# Debug 额外执行 gdb 断点、参数和调用栈检查（需安装 gdb）
cmake -S . -B /tmp/devbox-cpp-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build /tmp/devbox-cpp-debug -j 4
ctest --test-dir /tmp/devbox-cpp-debug --output-on-failure

# ASan/UBSan 和 TSan 必须使用不同的目录
cmake -S . -B /tmp/devbox-cpp-asan -DCMAKE_BUILD_TYPE=Debug -DDEVBOX_SANITIZER=address
cmake --build /tmp/devbox-cpp-asan -j 4
ctest --test-dir /tmp/devbox-cpp-asan --output-on-failure
cmake -S . -B /tmp/devbox-cpp-tsan -DCMAKE_BUILD_TYPE=Debug -DDEVBOX_SANITIZER=thread
cmake --build /tmp/devbox-cpp-tsan -j 4
ctest --test-dir /tmp/devbox-cpp-tsan --output-on-failure

cmake --install build --prefix /tmp/devbox-cpp-install
```

安装后消费者使用 `find_package(devboxIndex 1.0 REQUIRED CONFIG)` 和
`target_link_libraries(app PRIVATE devbox::project_index)`。调试和消毒器检查不能用 runtime
镜像，它只用来检验正常 CLI 产物。部分宿主的高地址随机化使 TSan 在进入 main 前报告
`unexpected memory mapping`；本机使用容器 `--security-opt seccomp=unconfined`，
在容器内以 `setarch "$(uname -m)" -R ctest ...` 仅关闭测试进程 ASLR 后通过。
不修改宿主 sysctl，也不把消毒器启动失败当作测试通过。

`tests/check-build.sh` 是现有自动化环境可调用的项目入口；本卡未修改共享工作流，
因此没有声称新增了提交触发的 GitHub Actions job。

## 扩展 CLI

```bash
./build/devbox-cpp-project --help
./build/devbox-cpp-project --workers 4 /path/to/file.txt alpha
./build/devbox-cpp-project --expr /path/to/file.txt '(alpha AND beta) OR delta'
```

原单词接口保留原文、行号、`NO_MATCH`（包括非法单词）的既有输出。
表达式文法仅由 `--expr` 开启：大写 `AND` 优先于 `OR`，支持括号，词元仍是 ASCII
字母/数字并统一小写。非法表达式、无效选项和不完整数值退出 2；文件或内部失败退出 1，
诊断仅写 stderr。表达式深度限 64，worker 数限 1–64；默认保持单线程。

## 查询库的协作结构

`InvertedIndex` 继续提供 `build/find/line/query`。新 `build(path, workers, factory)` 按行
分配线程任务，每个 worker 独占解析器、词元池和倒排分片；谓词条件变量启动，原子任务
编号不保护其他数据；完成计数 release/acquire 发布分片，主线程在 join 之前归并排序，
再 join 和发布不可变快照，普通倒排数据的可见性确实依赖原子内存序而非仅靠 join。
文本解析器索引所有词，
TSV 解析器把首列当文档键而只索引后续列（无 tab 的行仍按普通文本解析）。
工厂的 `create()`
可能并发调用，必须无数据竞争；返回 null 或抛出异常均令构建失败并保留旧索引。
映射时输入文件必须保持不变，外部并发截断不在本库的进程安全保证内。

查询链是 `QueryBuilder → Expression AST → QuerySource → HitOrder → QueryRenderer`。
请求拥有不可变 AST，支持范围、条数和排序。来源可选拥有快照、旧接口适配或延迟磁盘加载；
渲染可选原格式或转义 TSV。`BackendFactory` 一次性产出配套来源和存储，
`Backend` 不开放混配构造，存储写入后同步替换来源。

`QuerySession` 协调编辑端与展示端，并用弱订阅通知缓存失效。通知复制注册列表；
期间取消订阅只影响下次通知，回调异常会在所有观察者收到通知后重新抛出。
成功替换索引也刷新展示。`RebuildCommand` 保存真实索引快照供撤销；
会话备忘录保存请求供回滚，不向外暴露可变历史。
`BuildJob` 状态对象实现待办→进行→完成，工作失败保持进行态并传播异常，可重试。
会话、缓存和可替换来源限同一线程使用；不可变索引的多个只读查询以及
`LazyQuery` 的并发首次加载可安全并行，禁止同一个索引的 build 与 find 并发。

`vocabulary()` 返回拥有排序副本的词项范围，其 forward iterator 不随索引重建失效，
但不允许在遍历中替换范围本身。`TokenPool` 只共享内在词字符串，位置仍在倒排表。
它减少同一分片内重复词元对象，并非声称跨线程全局共享或一定提高速度。

## 持久化与 C ABI

`save(path)/load(path)` 使用 8 字节头 `DBIX 01 00 00 00`，之后是小端 u64 行数，
每条记录为小端 u64 字节数和原文（可含 NUL，不含换行）。随后是 u64 词项数和按词序排列的
字典：u64 词字节数、词、u64 倒排条目数、逐个 u64 行号。存储真实倒排表，保留空行和
不同解析策略的结果，无需依赖 STL、结构体布局或 ABI。拒绝非法头/版本、越界长度、
非规范词项、重复/无序/越界倒排条目、截断和尾部垃圾；
加载失败保留旧快照。它不是带校验和的防篡改格式，合法文本字节被改动无法自动识别。
保存检查写入/关闭错误并提供路径上下文，但不是断电安全的事务写入，调用方应保留备份。

`index_c.h` 可由 C 编译器包含：`devbox_index_open` 返回 opaque handle，
`devbox_index_count` 查询命中行数，`devbox_index_close` 释放。调用方提供错误缓冲，
非零返回码区分输入和内部失败；open 失败输出 handle 置空，异常不会越过 C 边界。
成功时不应读取旧错误缓冲；缓冲可为 NULL/0，但调用方仍必须检查返回码。
`tests/test_ffi.c` 是真正的 C 翻译单元，不用 C++ 伪装调用方。

## 基准

`bench_index <file> <word>` 预热一次，再各采样 7 次单线程/4 worker 构建。
每次做 1000 次查询，stderr 报构建中位微秒、查询中位纳秒和防止无用计算的校验和。
同一输入的 worker 配置校验和应一致。小文本的线程/分片开销可能超过收益，
不以单次耗时或特定机器阈值作为正确性测试；有 perf 的环境可执行
`perf record -g -- ./build/bench_index <file> <word>` 分析热点。

## 在 runtime 镜像里怎么验

```bash
bash check-runtime.sh
```
