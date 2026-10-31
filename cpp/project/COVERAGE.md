# C++ 毕业项目：用例覆盖表

本表记录已接入用例及其代码位置，由 `scripts/coverage-check.sh cpp` 校验用例存在性和代码引用。
当前覆盖 `hello`、35 个 L1、12 个 L2、6 个 L3 和 23 个 L4，共 77 个用例，pending 为 0。
新增落点以类/函数名定位，避免格式化和后续实现调整令行号失效。

## 怎么加一行

1. 在实现或测试代码中用注释写上对应的用例 ID；校验会在代码中查找 ID（不检查本表自身），以避免覆盖表只靠自己的声明“自证”。
2. 在下面的覆盖表中增加该用例的一行，并填写准确的文件位置和说明。
3. 删除该用例 README 中的 `<!-- coverage: pending -->` 行，再运行
   `bash scripts/coverage-check.sh cpp` 自检。表内按 ID 升序排列。

## 覆盖表

| 用例ID | 落点 | 说明 |
|---|---|---|
| L1-001-references-pointers | include/index.h:InvertedIndex::find、query | 引用传入只读查询词，指针表达可缺失结果和可选筛选器，空字符指针可安全查询 |
| L1-002-const-correctness | include/index.h:InvertedIndex::find、line | const 索引只读查询，返回 const 倒排表指针和 const 行文本引用 |
| L1-003-lifetime-copy-control | include/index.h:InvertedIndex 构造/赋值 | 显式五法则：拷贝共享不可变快照，重建独立替换，移动后可复用 |
| L1-004-raii | src/index.cpp:MappedFile | 文件描述符和 mmap 随作用域释放，构建分配异常也自动清理 |
| L1-005-move-semantics | src/index.cpp:InvertedIndex::build | 移动发布已完成的索引缓冲区所有权，避免逐个复制词项和行文本 |
| L1-006-perfect-forwarding | include/index.h:Match::for_each | 查询遍历包装器转发回调，左值复制、右值移动，支持 move-only 捕获 |
| L1-007-smart-pointers | include/index.h:Match；tests/test_index.cpp | 查询结果共享不可变文本快照；测试以 unique_ptr 管理多态筛选器、weak_ptr 观察释放 |
| L1-008-template-basics | include/index.h:detail::append_unique | 去重追加模板用于倒排行号，测试还实例化 string 序列 |
| L1-009-template-constraints | include/index.h:detail::append_unique、Match::for_each | concepts 限定元素类型、可追加容器及回调签名，测试断言错误类型不可调用 |
| L1-010-stl-containers | include/index.h:InvertedIndex::Data | vector 保存有序行号与文本，unordered_map 保存词项到倒排表 |
| L1-011-container-selection | include/index.h:InvertedIndex::Data | 哈希容器按词查找，连续容器顺序扫描，不依赖哈希迭代顺序 |
| L1-012-iterators-algorithms | src/index.cpp:Match::line、InvertedIndex::query | copy_if 筛选倒排表，binary_search 检查结果成员，不跨扩容保留迭代器 |
| L1-013-string-view | src/index.cpp:InvertedIndex::build、normalize_word | mmap 切片复制原文后分词；查询可接受非零结尾切片 |
| L1-014-lambda-captures | src/index.cpp:parse_line、InvertedIndex::query | 分词闭包借用存活至 join 的缓冲区；查询闭包捕获快照与筛选器 |
| L1-015-type-deduction | src/index.cpp:InvertedIndex::query | const auto& 保留倒排表引用与只读性，避免 auto 按值复制 |
| L1-016-constexpr | include/index.h:detail::checked_add | constexpr 加法可在编译期断言，也用于运行期统计与行号检查 |
| L1-017-structured-bindings | src/index.cpp:InvertedIndex::statistics | 按 const 引用拆解词项与倒排表，统计时不复制容器 |
| L1-018-initialization | include/index.h:LineRange | 行号范围以 size_t 花括号初始化，默认起点为 1，避免未初始化及窄化 |
| L1-019-overload-resolution | include/index.h:InvertedIndex::find | string、string_view、const char* 查询重载；字符指针重载消除字符串字面量歧义 |
| L1-020-operator-overloading | include/index.h:LineRange::operator== | 行号范围用默认相等运算符按两个端点比较，测试验证等价和不等价 |
| L1-021-enum-class | include/index.h:InvertedIndex::State | 强类型状态区分未构建和已构建空索引，失败重建不改变原状态 |
| L1-022-inheritance-polymorphism | include/index.h:LinePredicate | 查询通过基类接口调用行范围或自定义文本筛选器 |
| L1-023-virtual-destructor | include/index.h:LinePredicate；tests/test_index.cpp | 基类虚析构保证 unique_ptr 删除派生筛选器时释放其资源，弱观察者验证 |
| L1-024-exception-safety | src/index.cpp:InvertedIndex::build；tests/allocation_failure.cpp | 在独立快照构建成功后才提交，注入 bad_alloc 验证旧索引和文本保留 |
| L1-025-undefined-behavior | src/index.cpp:InvertedIndex::build、line | 空映射不做指针算术，扫描先查边界，行号 0 与越界抛出 out_of_range |
| L1-026-explicit-casts | src/index.cpp:MappedFile | 先检查文件长度可表示性再转 size_t，将 mmap 的 void* 显式转为字节指针 |
| L1-027-namespaces | include/index.h:devbox、detail | devbox 隔离公共索引名称，detail 与匿名命名空间隔离实现工具 |
| L1-028-optional-variant | include/index.h:QueryResult、InvertedIndex::frequency | variant 区分非法词、未命中和持有快照的结果；optional 表达缺失的文档频次 |
| L1-029-pair-tuple | src/index.cpp:InvertedIndex::statistics | pair 返回词项数和倒排条目数，测试用结构化绑定读出两个统计值 |
| L1-030-static-assert | include/index.h；tests/test_index.cpp | 静态断言检查编译期加法、索引 noexcept 移动及模板不可调用类型 |
| L1-031-function-callbacks | include/index.h:Match::for_each | 查询结果调用匹配签名的函数指针、无捕获 lambda 和捕获闭包 |
| L1-032-numeric-overflow | include/index.h:detail::checked_add；src/index.cpp:MappedFile | 加法前检查溢出，文件长度先检查转换范围，测试覆盖 size_t 最大值边界 |
| L1-033-array-types | src/index.cpp:normalize_word | array 保存短查询归一化缓冲区，长查询用动态 string，测试覆盖 64/65 字节边界 |
| L1-034-preprocessor | include/index.h:头文件保护 | 头文件保护与 C++20 预处理检查；常量和字符转换用 constexpr 而非文本替换宏 |
| L1-035-noexcept | include/index.h:InvertedIndex 移动构造/赋值 | 索引移动转移 shared_ptr 和诊断字符串，静态断言其不抛异常；有分配的接口保留异常传播 |
| L2-001-multifile-odr | include/index.h；src/index.cpp；src/query.cpp；tests/test_index.cpp | 公开声明与实现拆分，多个翻译单元链接同一个库，重复包含头文件 |
| L2-002-cmake-targets | CMakeLists.txt；tests/check-build.sh | target 依赖、安装导出、版本化 find_package 消费者与 CPack TGZ |
| L2-003-reproducible-build | CMakeLists.txt；tests/check-build.sh | 必须 C++20、禁扩展、目标级严格警告，全新目录 Release 构建 |
| L2-004-file-io | src/index.cpp:MappedFile、save、load；tests/test_query.cpp:SerializationCase | 路径化文件错误，流读写持久化，空文件、目录与缺失输入测试 |
| L2-005-test-harness | tests/test_index.cpp；tests/test_query.cpp:TestCase；CMakeLists.txt | Release 下 -UNDEBUG，正常、边界、异常路径以非零退出失败 |
| L2-006-sanitizers | CMakeLists.txt:DEVBOX_SANITIZER | Werror、ASan/UBSan 和独立 TSan 构建，错误选项配置时拒绝 |
| L2-007-gdb-debugging | tests/check-debug.sh；CMakeLists.txt:debugger_test | Debug 断在 query，检查参数 alpha 和回溯到 main |
| L2-008-cli-interface | src/main.cpp；tests/test_cli.sh | --help、--workers 完整数值解析、--expr 显式启用文法；错误返回 2 |
| L2-009-project-layers | include/index.h:IndexApplication；src/query.cpp | CLI、索引、存储、查询 AST 和渲染独立；库测试不依赖 main |
| L2-010-dependency-integration | CMakeLists.txt；cmake/devboxIndexConfig.cmake.in | Threads 显式目标依赖，导出包重复发现依赖，无未声明的下载库 |
| L2-011-error-reporting | src/index.cpp:MappedFile；src/query.cpp:ErrorHandler；src/main.cpp | 读取失败保留操作和路径；参数、IO、内部错误经链分派到 stderr |
| L2-012-ci-build-test | tests/check-build.sh | 项目内自动化入口执行干净构建、CTest、安装消费者与打包，不改共享 CI |
| L3-001-mmap-files | src/index.cpp:MappedFile、InvertedIndex::build | 空映射、长度、常规文件检查；映射释放前复制原文 |
| L3-002-thread-synchronization | src/index.cpp:InvertedIndex::build；tests/test_query.cpp:ParallelCase | stop-aware 条件变量谓词启动线程，分片独占写入，退出前 join，异常回传 |
| L3-003-atomics-memory-order | src/index.cpp:next_line、completed、merge_shards | relaxed 分配唯一任务；release 完成/acquire 等待发布后，在 join 前读取归并普通分片数据 |
| L3-004-profiling-benchmarks | bench/bench_index.cpp | 预热一次、7 次采样、每次 1000 查询，中位数与校验和，比较 1/4 worker |
| L3-005-binary-serialization | src/index.cpp:save、load；tests/test_query.cpp:SerializationCase | DBIX 版本头、显式小端、原文和真实倒排字典；校验词项/行号顺序、长度、截断及尾部数据 |
| L3-006-ffi-abi | include/index_c.h；src/index_c.cpp；tests/test_ffi.c | 真 C 调用方，opaque handle，显式 close，错误缓冲和返回码隔离异常 |
| L4-001-singleton | include/index.h:IndexConfig；src/index.cpp:instance | 唯一配置入口，删除复制；原子 worker 配置在 build 入口读取 |
| L4-002-factory-method | include/index.h:ParserFactory、TextParserFactory、TsvParserFactory | 子类工厂创建文本/TSV 解析器，构建只依赖工厂抽象 |
| L4-003-abstract-factory | include/index.h:BackendFactory、MemoryBackendFactory、LocalBackendFactory；src/query.cpp:MemoryStore、LocalStore | 成组创建来源与存储，私有 Backend 构造避免客户混配，写入同时更新来源 |
| L4-004-builder | include/index.h:QueryBuilder；src/query.cpp:build | 表达式必填，范围/条数/排序可选；构建返回独立、已校验请求 |
| L4-005-prototype | include/index.h:IndexPrototype、SnapshotSource；src/query.cpp:clone | 克隆复用不可变预置索引，替换副本不重建也不影响原对象 |
| L4-006-adapter | include/index.h:LegacyQueryAdapter；src/query.cpp:lookup | 不重写旧 find/line 逻辑，将借用指针接口适配为拥有型 Hits |
| L4-007-bridge | include/index.h:QueryRenderer、PlainRenderer、TsvRenderer、QuerySource | 输出和来源两个独立多态维度，测试文本/TSV × 旧接口/延迟来源 |
| L4-008-composite | include/index.h:Expression、TermExpression、GroupExpression、AndExpression、OrExpression | 叶子与多子节点统一递归求值，用 AST 树而非额外目录树样板 |
| L4-009-decorator | include/index.h:CountingQuery、CachedQuery；src/query.cpp:lookup | 同一查询接口叠加计数和缓存；两种包装顺序具有不同可测计数 |
| L4-010-facade | include/index.h:IndexApplication；src/query.cpp:run；src/main.cpp:--expr | 单入口委托请求解析、索引构建、后端创建和渲染，CLI 明确开启 |
| L4-011-flyweight | include/index.h:TokenPool；src/index.cpp:intern、TokenParser::parse | 每个构建分片复用相同词元对象，行号保留在外部倒排表，不写入共享词元 |
| L4-012-proxy | include/index.h:LazyQuery；src/query.cpp:lookup | 同一查询接口首次调用才 load，锁保证并发只加载一次，原子访问计数 |
| L4-013-chain-of-responsibility | include/index.h:ErrorHandler；src/query.cpp:diagnostic_chain | 三个处理者按错误级别处理或传递，unique_ptr 无环，未处理明确失败 |
| L4-014-command | include/index.h:RebuildCommand；src/query.cpp:execute、undo | 重建保存真实旧快照，撤销准确恢复；失败执行不产生可撤销历史 |
| L4-015-interpreter | include/index.h:Expression；src/query.cpp:ExpressionParser、evaluate | AND 高于 OR，括号递归，节点多态交/并集，非法输入及深度超限拒绝 |
| L4-016-iterator | include/index.h:Vocabulary::Iterator；InvertedIndex::vocabulary | 自定义 forward iterator 顺序遍历词项；拥有排序副本，重建后不失效 |
| L4-017-mediator | include/index.h:QuerySession、QueryEditor、ResultView；src/query.cpp:change、replace | 编辑端与展示端不互持，会话协调求值、更新及展示 |
| L4-018-memento | include/index.h:InvertedIndex::Snapshot、QuerySession::Memento；src/query.cpp:restore | 不可修改的内部快照；索引撤销和查询会话回滚分别保存状态 |
| L4-019-observer | include/index.h:UpdateListener、QuerySession；src/query.cpp:subscribe、replace | 索引替换按注册顺序通知缓存失效，弱订阅、取消订阅、复制通知列表 |
| L4-020-state | include/index.h:TaskState、BuildJob；src/query.cpp:PendingTask、RunningTask、DoneTask | 状态对象决定待办→进行→完成；失败保留进行态并传播；CLI 真实执行构建 |
| L4-021-strategy | include/index.h:HitOrder、LineOrder、LengthOrder；src/query.cpp:execute_query | 同一请求流程切换按行或稳定按长度排序，先排序再截取条数 |
| L4-022-template-method | tests/test_query.cpp:TestCase、ParallelCase、SerializationCase | 非虚 run 固定准备→执行→校验；两个真实专题测试复用骨架 |
| L4-023-visitor | include/index.h:ExpressionVisitor、TermCountVisitor、ExplainVisitor；src/query.cpp:visit | 节点 accept 双分派；统计词数与解释查询两种分析独立于 AST 节点 |
| hello | src/main.cpp:2 | 保留阶段 0 的基础用例引用 |

## 自检

bash scripts/coverage-check.sh cpp

## pending：用例已落地但项目还没接入

阶段 2 铺开用例时，项目骨架只真实用到 `hello` 一个。用例若还没被 `project/` 引用，
就在它自己的 `README.md` 里写一行：

```markdown
<!-- coverage: pending -->
```

`scripts/coverage-check.sh` 会对这类用例豁免「必须在表里声明」和「必须在代码里出现」两条，
但会单独统计并打印 pending 数量 —— 它是**明账上的欠债，不是通过**。
阶段 4 收口时用 `bash scripts/coverage-check.sh --strict`，pending 未清零即失败。

## L1 接入后的接口约定

- 保留原 `build`、`find`、`line` 接口和 CLI 的行号、原文、`NO_MATCH` 输出。
  `find` 的原始指针和 `line` 的引用只在当前索引快照未被替换或释放时有效；
  查询字符指针允许为空，string_view 不必以零结尾。`line(0)` 或越界显式抛异常。
- `query` 返回非法词 `QueryError`、未命中 `monostate` 或 `Match`。
  `Match` 持有共享快照，在索引重建或销毁后仍可读取原命中文本；
  只允许读取命中的行。可选 `LinePredicate*` 只在同步查询期间借用，nullptr 表示不筛选。
- `Match::for_each` 同步遍历，复制左值回调、移动右值回调，不保留回调；
  筛选器和回调异常向调用者传播，不改变索引。索引移动和只读状态访问不抛异常。
- `frequency` 返回词的命中文档行数（不是词在原文的重复次数），非法词或未命中均为 nullopt。
  `statistics` 返回 `{词项数, 所有倒排表条目总数}`，不依赖哈希遍历顺序。
  `build` 读文件失败返回 false，分配失败传播异常，两者都保留原快照。

## 完成情况（CPP-01）

35 个 L1 用例均已落实实际代码、登记上表、删除 README 的 pending 行，没有无法接入的考点。
清单中落点为「—」的项补在同一索引模块的回调、通用容器工具、行范围筛选和编译期契约中，
没有为单个 ID 拆分接口。智能指针采用无环共享快照，而不是人为引入循环；弱引用释放验证在测试中。
完整类/函数定位见上表。

验收结果：

- 覆盖校验为 `77 个用例，其中 pending 41`，非 pending 覆盖 `36 / 36`。
- 临时删除 L1-030 表格行后，覆盖校验明确报告未声明并返回非零；已恢复该行并重新校验。
- Release 构建、CTest、ASan/UBSan、格式检查和 runtime 镜像查询均通过；
  CLI 正常查询与未命中输出保持原约定，基准可运行。
- `TAG=local scripts/run-example.sh cpp --all`：77 通过、0 失败。
  示例文件的改动只有 35 个 README 各删除一行 pending，未修改 run.sh 或 expected.txt。

环境说明：仓库中未找到要求必读的 `00-CONVENTIONS.md`，遵循现有代码风格和两份 C++ 规范。
主机缺少 CMake，且 glibc 比构建镜像旧，构建和运行使用已有的
`ghcr.io/zeek-zhao/devbox-cpp:local`；产物保留在 `cpp/project/build/`，
另以 `check-runtime.sh` 验证 runtime 镜像中的实际运行。

## 完成情况（CPP-02）

- 已落地：接入已有 41 个用例（L2 12、L3 6、L4 23）；完整 ID 列表及每个模式的
  类/函数落点见上表 L2-001 到 L4-023 的 41 条记录，未新增或修改示例业务代码。
- 自测：`TAG=local scripts/run-example.sh cpp --all` → 77 / 77 PASS。
- 覆盖：`coverage-check.sh cpp` → pending 0、覆盖 77 / 77、声明 77 条
  （本卡消除 pending 41，没有新增 pending）；`coverage-check.sh --strict cpp` → rc=0。
- 全语言严格模式：`coverage-check.sh --strict` → rc=1，唯一失败原因是
  go/python/java 各 23 个 pending，总计 69；cpp/rust/shell 都为 0。
  卡中“全语言严格模式通过但保留这 69 个 pending”的预期与现有判定实现矛盾，
  本卡没有修改判定脚本、其他语言或共享工作流去放宽它。
- 构建与运行：Release `BUILD_OK`、CTest 4 / 4、Debug（含 gdb）5 / 5、
  ASan/UBSan 4 / 4、TSan 4 / 4、runtime 镜像真实查询均通过。
  宿主没有 CMake，使用已有 `devbox-cpp:local` 构建；runtime 使用已有 `:latest`。
- 工程检查：干净构建、安装、独立消费者 find_package 及 CPack TGZ 通过；
  `shellcheck -S warning cpp/examples/*/run.sh` 及项目脚本通过。
- 格式：`TAG=local bash scripts/fmt.sh --check --lang cpp` → rc=0。
  CMake 生成的 compiler-id 源码曾被共享检查扫描；只清理这个构建生成文件，
  未修改格式脚本、配置或任何别人的示例。
- 反向：暂删 L4-023 表格行，覆盖校验明确 FAIL，恢复后通过。
  在独立临时项目中分别注入 23 个模式故障和并发/序列化/ABI 故障，26 / 26 检出；
  另将完成发布的 release 改成 relaxed，TSan 明确报告数据竞争并退出 66。
  所有故障副本已删除，真实工作区未保留故障。
- 发现的问题：除严格模式预期矛盾、TSan 宿主 ASLR 启动限制及生成文件格式扫描外，无。
  TSan 使用 README 记载的进程级 ASLR 关闭方式通过，未修改宿主设置。

### 模式落点的取舍

23 个模式不是 23 套独立演示：查询 AST 同时承载组合、解释器和访问者；来源与存储、
渲染和装饰器组成一条查询链；索引与会话快照承载原型、命令、备忘录；更新通知失效缓存，
任务状态机真实包住 CLI 构建。每个模式的对应测试都会在相关行为被改坏时失败。

有三个落点偏离清单示意，但没有假装它们是索引的固有需要：组合用在嵌套查询 AST，
不另造一个项目不使用的目录树；中介者用在库的编辑/展示会话协议，不添加 GUI；
模板方法用在真实并发与持久化测试骨架，不放进主实现。单例只管理 worker 默认配置；
显式 build 参数仍可覆盖，避免把业务依赖强制绑成全局。FFI 作为实际可安装 C API，
依赖集成使用必需的系统 Threads，而不是为了“外部依赖”下载无用库。

### 项目代码量变化

`git diff --stat cpp/project/`：9 个已跟踪文件，新增 1201 / 删除 111 行。
另有 12 个新文件共 1153 行（尚未 add，原命令不包含它们）。
合计 21 个项目文件，新增 2354 / 删除 111 行，净增 2243 行。

基准实测：100000 行 `alpha beta gamma alpha`，一次预热、7 次采样。
单线程构建中位数 15993 us，4 worker 为 17160 us；查询均为 16 ns，
校验和均为 800000000。本次采样并行反而更慢，不能声称已有确定加速收益。
