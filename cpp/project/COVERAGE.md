# C++ 毕业项目：用例覆盖表

本表记录已接入用例及其代码位置，由 `scripts/coverage-check.sh cpp` 校验用例存在性和代码引用。
当前覆盖 `hello` 和全部 35 个 L1 用例；其余 41 个用例仍为 pending。

## 怎么加一行

1. 在实现或测试代码中用注释写上对应的用例 ID；校验会在代码中查找 ID（不检查本表自身），以避免覆盖表只靠自己的声明“自证”。
2. 在下面的覆盖表中增加该用例的一行，并填写准确的文件位置和说明。
3. 删除该用例 README 中的 `<!-- coverage: pending -->` 行，再运行
   `bash scripts/coverage-check.sh cpp` 自检。表内按 ID 升序排列。

## 覆盖表

| 用例ID | 落点 | 说明 |
|---|---|---|
| L1-001-references-pointers | include/index.h:138 | 引用传入只读查询词，指针表达可缺失结果和可选筛选器，空字符指针可安全查询 |
| L1-002-const-correctness | include/index.h:138 | const 索引只读查询，返回 const 倒排表指针和 const 行文本引用 |
| L1-003-lifetime-copy-control | include/index.h:129 | 显式五法则：拷贝共享不可变快照，重建独立替换，移动后可复用 |
| L1-004-raii | src/index.cpp:51 | 文件描述符和 mmap 随作用域释放，构建分配异常也自动清理 |
| L1-005-move-semantics | src/index.cpp:181 | 移动发布已完成的索引缓冲区所有权，避免逐个复制词项和行文本 |
| L1-006-perfect-forwarding | include/index.h:109 | 查询遍历包装器转发回调，左值复制、右值移动，支持 move-only 捕获 |
| L1-007-smart-pointers | include/index.h:100 | 查询结果共享不可变文本快照；测试以 unique_ptr 管理多态筛选器、weak_ptr 观察释放 |
| L1-008-template-basics | include/index.h:30 | 去重追加模板用于倒排行号，测试还实例化 string 序列 |
| L1-009-template-constraints | include/index.h:31 | concepts 限定元素类型、可追加容器及回调签名，测试断言错误类型不可调用 |
| L1-010-stl-containers | include/index.h:90 | vector 保存有序行号与文本，unordered_map 保存词项到倒排表 |
| L1-011-container-selection | include/index.h:90 | 哈希容器按词查找，连续容器顺序扫描，不依赖哈希迭代顺序 |
| L1-012-iterators-algorithms | src/index.cpp:211 | copy_if 筛选倒排表，binary_search 检查结果成员，不跨扩容保留迭代器 |
| L1-013-string-view | src/index.cpp:168 | mmap 文本切片即时分词，需保留的行转为 string；查询可接受非零结尾切片 |
| L1-014-lambda-captures | src/index.cpp:171 | 同步分词闭包引用构建缓冲区、值捕获行号；查询闭包捕获快照与筛选器 |
| L1-015-type-deduction | src/index.cpp:233 | const auto& 保留倒排表引用与只读性，避免 auto 按值复制 |
| L1-016-constexpr | include/index.h:44 | constexpr 加法可在编译期断言，也用于运行期统计与行号检查 |
| L1-017-structured-bindings | src/index.cpp:257 | 按 const 引用拆解词项与倒排表，统计时不复制容器 |
| L1-018-initialization | include/index.h:58 | 行号范围以 size_t 花括号初始化，默认起点为 1，避免未初始化及窄化 |
| L1-019-overload-resolution | include/index.h:138 | string、string_view、const char* 查询重载；字符指针重载消除字符串字面量歧义 |
| L1-020-operator-overloading | include/index.h:61 | 行号范围用默认相等运算符按两个端点比较，测试验证等价和不等价 |
| L1-021-enum-class | include/index.h:96 | 强类型状态区分未构建和已构建空索引，失败重建不改变原状态 |
| L1-022-inheritance-polymorphism | include/index.h:66 | 查询通过基类接口调用行范围或自定义文本筛选器 |
| L1-023-virtual-destructor | include/index.h:68 | 基类虚析构保证 unique_ptr 删除派生筛选器时释放其资源，弱观察者验证 |
| L1-024-exception-safety | src/index.cpp:157 | 在独立快照构建成功后才提交，注入 bad_alloc 验证旧索引和文本保留 |
| L1-025-undefined-behavior | src/index.cpp:168 | 空映射不做指针算术，扫描先查边界，行号 0 与越界抛出 out_of_range |
| L1-026-explicit-casts | src/index.cpp:26 | 先检查文件长度可表示性再转 size_t，将 mmap 的 void* 显式转为字节指针 |
| L1-027-namespaces | include/index.h:26 | devbox 隔离公共索引名称，detail 与匿名命名空间隔离实现工具 |
| L1-028-optional-variant | include/index.h:125 | variant 区分非法词、未命中和持有快照的结果；optional 表达缺失的文档频次 |
| L1-029-pair-tuple | src/index.cpp:250 | pair 返回词项数和倒排条目数，测试用结构化绑定读出两个统计值 |
| L1-030-static-assert | include/index.h:52 | 静态断言检查编译期加法、索引 noexcept 移动及模板不可调用类型 |
| L1-031-function-callbacks | include/index.h:109 | 查询结果调用匹配签名的函数指针、无捕获 lambda 和捕获闭包 |
| L1-032-numeric-overflow | include/index.h:44 | 加法前检查溢出，文件长度先检查转换范围，测试覆盖 size_t 最大值边界 |
| L1-033-array-types | src/index.cpp:101 | array 保存短查询归一化缓冲区，长查询用动态 string，测试覆盖 64/65 字节边界 |
| L1-034-preprocessor | include/index.h:1 | 头文件保护与 C++20 预处理检查；常量和字符转换用 constexpr 而非文本替换宏 |
| L1-035-noexcept | include/index.h:132 | 索引移动仅转移 shared_ptr，静态断言其不抛异常；有分配的接口保留异常传播 |
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
完整文件行号见上表。

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
