# C project coverage

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.c:63 | 自检成功后输出稳定结果，保留轨道最小可运行入口的行为。 |
| L1-001-types-sizes | src/pool/pool.c:39 | 依据池元数据的真实类型分配其正确大小。 |
| L1-002-integer-promotion | README.md:51 | 请求处理没有窄整数算术，硬加入会制造无关边界。 |
| L1-003-unsigned-wraparound | README.md:52 | 长度使用有界检查，不需要依赖回绕的协议逻辑。 |
| L1-004-fixed-width-types | src/net/server.c:58 | 端口通过明确的 `uint16_t` 边界进入监听配置。 |
| L1-005-pointer-arithmetic | src/pool/pool.c:54 | 按步长定位每个连续池块，以避免逐对象分配。 |
| L1-006-pointer-diff | README.md:55 | 内存位置使用明确的 `size_t` 偏移，无指针差值需求。 |
| L1-007-array-decay | src/net/server.c:120 | 非阻塞读取直接填入定长请求缓冲区。 |
| L1-008-string-functions | src/http/http.c:40 | 请求行解析用字符串分隔符切出方法和路径。 |
| L1-009-struct-layout | src/net/server.c:220 | 池以客户端结构体大小创建固定槽位。 |
| L1-010-struct-padding | README.md:59 | 网络响应逐字段格式化，不传输结构体内存布局。 |
| L1-011-bitfields | README.md:60 | Socket/协议标志不需要编译器相关的位域布局。 |
| L1-012-bitops | src/net/server.c:45 | 设置非阻塞模式必须在已有文件标志上置位。 |
| L1-013-union-type-punning | README.md:62 | 服务不需重解释任何对象表示，加入双关没有协议用途。 |
| L1-014-enum-values | src/net/server.c:103 | 客户端状态区分读阶段和写阶段，驱动事件分派。 |
| L1-015-const-pointer | src/http/http.c:22 | 固定路由配置在请求期间保持只读。 |
| L1-016-function-pointers | src/http/http.c:88 | 路由条目调用其处理函数返回对应响应体。 |
| L1-017-typedef | src/http/http.c:7 | 路由回调使用命名函数指针类型表达统一签名。 |
| L1-018-initializers | src/net/server.c:186 | 明确指定地址结构成员，避免依赖成员顺序。 |
| L1-019-compound-literals | src/net/server.c:185 | 一次构造监听地址值并初始化局部地址对象。 |
| L1-020-malloc-free | src/pool/pool.c:39 | 池元数据和块存储动态分配，并由销毁路径释放。 |
| L1-021-calloc-realloc | README.md:70 | 客户端池容量固定，不需要数组扩容或 `realloc`。 |
| L1-022-memory-leak-pattern | src/net/server.c:222-224 | 池创建失败时释放已创建的 epoll 和监听描述符。 |
| L1-023-double-free-guard | src/pool/pool.c:90-93 | 释放块前查空闲链，防止重复入链和重复分配。 |
| L1-024-2d-arrays | README.md:73 | 服务只处理字节流，不进行二维数据运算。 |
| L1-025-vla-limits | README.md:74 | 请求缓冲区有编译期固定上限，无运行期数组需求。 |
| L1-026-flexible-array-member | README.md:75 | 固定槽位池不需要可变尾部对象布局。 |
| L1-027-stdlib-qsort | README.md:76 | 路由表固定且顺序无关，不需要运行期排序。 |
| L1-028-bsearch | README.md:77 | 两条路由顺序扫描比额外排序/查找更直接。 |
| L1-029-setjmp-longjmp | README.md:78 | 返回值和状态机足以处理服务错误，无非局部跳转需要。 |
| L1-030-static-local | README.md:79 | 服务生命周期由显式状态管理，不需隐藏的函数静态状态。 |
| L1-031-internal-linkage | src/http/http.c:18 | 内置健康路由处理器仅在该翻译单元内部使用。 |
| L1-032-do-while-macro | README.md:81 | 项目没有多语句宏，故无需此控制流保护模式。 |
| L1-033-macro-stringify | README.md:82 | 路由和诊断不生成预处理器标识符或字符串。 |
| L1-034-include-guard | src/http/http.h:1 | 公开接口可经多个模块包含而不重复定义。 |
| L2-001-multifile-build | Makefile:6 | 五个模块拆分为翻译单元后统一链接。 |
| L2-002-makefile-incremental | Makefile:17-18 | 对象规则与生成依赖文件使头文件变更触发重编。 |
| L2-003-header-dependency | src/http/http.c:1 | 实现依赖模块公开头文件中的接口声明。 |
| L2-004-conditional-compilation | README.md:87 | 目标运行平台固定为 Linux，无平台分支实现需要。 |
| L2-005-assert-ndebug | README.md:88 | 外部输入采用显式运行时检查，不能依赖可移除断言。 |
| L2-006-asan-bounds | README.md:89 | Sanitizer 是独立测试工具，不构成 HTTP 服务功能。 |
| L2-007-ubsan-overflow | README.md:90 | 数值边界被检查；专门触发未定义溢出与服务目标无关。 |
| L2-008-gdb-batch-backtrace | README.md:91 | 调试器调用不属于服务器运行时行为。 |
| L2-009-leak-detection | src/main.c:22 | 自检销毁堆分配池，供外部内存检查器验证释放。 |
| L2-010-strict-warnings | Makefile:3 | 警告升级为错误，保证项目按严格 C17 编译。 |
| L2-011-gcc-analyzer | README.md:94 | 静态分析器是额外诊断工具，不是服务本身行为。 |
| L2-012-file-io | README.md:95 | HTTP 请求应答不要求文件持久化。 |
| L2-013-cli-args | src/main.c:69 | 唯一可选参数显式选择模块自检。 |
| L2-014-errno-handling | src/net/server.c:52-58 | `strtoul` 失败时立即检查并拒绝无效端口值。 |
| L2-015-log-macro | README.md:98 | 日志刻意不记录易变化的源位置，保持确定性。 |
| L2-016-print-formats | src/http/http.c:106 | 响应长度使用与 `size_t` 匹配的格式说明符。 |
| L2-017-reproducible-build | README.md:100 | 项目不做归一化路径或跨构建产物比较。 |
| L2-018-unit-test-harness | src/main.c:59-64 | 自检函数验证池、arena、解析器和日志的关键行为。 |
| L2-019-struct-by-value-abi | README.md:102 | 大型连接对象按指针传递，无按值 ABI 需求。 |
| L2-020-optimization-consistency | README.md:103 | 项目不比较优化级别；此类构建矩阵与服务运行无关。 |
| L3-001-alignment | src/pool/pool.c:114-125 | arena 对齐请求路径内的字符串分配。 |
| L3-002-cache-locality | src/pool/pool.c:53-55 | 连续客户端块按固定步长存放，便于紧凑分配。 |
| L3-003-memory-pool | src/net/server.c:97 | 新连接复用有界客户端槽，不逐连接分配对象。 |
| L3-004-arena-allocator | src/http/http.c:79 | 路由路径暂存于连接 arena，无单独堆分配。 |
| L3-005-hash-table-chaining | README.md:108 | 两个固定路由不需要可变哈希桶和删除语义。 |
| L3-006-dynamic-array | README.md:109 | 协议缓冲区按安全上限固定，不需要扩容数组。 |
| L3-007-intrusive-list | README.md:110 | epoll 直接携带客户端指针，无列表遍历任务。 |
| L3-008-binary-heap | README.md:111 | 调度顺序由内核事件循环决定，不需优先队列。 |
| L3-009-ring-buffer | src/log/log.c:12-21 | 有界日志满时覆盖最旧记录，限制常驻内存。 |
| L3-010-string-builder | README.md:113 | 响应尺寸固定且有界，`snprintf` 已能安全构造。 |
| L3-011-endianness | README.md:114 | HTTP 内容是文本，地址字节序由 POSIX 转换函数处理。 |
| L3-012-varint | README.md:115 | 当前文本协议子集不含变长整数编码字段。 |
| L3-013-crc32 | README.md:116 | 路由服务没有校验和或内容完整性标签需求。 |
| L3-014-bitboard | README.md:117 | 位棋盘集合表示与 HTTP 请求分派无关。 |
| L3-015-float-precision | README.md:118 | 端口、长度和状态均为整数，不解析浮点数。 |
| L3-016-overflow-safe-add | src/pool/pool.c:23-27 | 对齐步长计算前检查加法溢出，防止错误分配尺寸。 |
| L3-017-bsearch-variants | README.md:120 | 两项路由表不需要排序后再做边界查找。 |
| L3-018-merge-sort | README.md:121 | 路由与日志没有稳定排序需求。 |
| L3-019-quickselect | README.md:122 | 请求处理不存在第 k 项选择工作负载。 |
| L3-020-matrix-blocking | README.md:123 | 服务不进行矩阵运算，分块计算无自然落点。 |
| L3-021-struct-serialization | README.md:124 | HTTP 字段按文本解析，不存取版本化 C 结构记录。 |
| L3-022-error-code-design | src/http/http.c:73-75 | 解析失败通过明确状态码构造 400 响应。 |
| L3-023-debug-build-macros | README.md:126 | 运行不依赖调试宏，避免关闭追踪改变参数求值。 |
