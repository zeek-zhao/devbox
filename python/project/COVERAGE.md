# Python 毕业项目：51 个用例全量覆盖

落点相对 `python/project/`，ID 注释紧邻实际知识点代码。
`src/` 仅使用 runtime 已有模块；依赖完整开发环境的知识点落在 `tests/`，
验证同一 CSV 管线的输入、输出、扩展和运行边界，不会被 runtime 导入。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | tests/test_pipeline.py:436 | 验证 Python 3.12、固定计算与 dataclass 期望对象 |
| L1-001-name-object | tests/test_pipeline.py:240 | 重绑定记录列表，旧别名仍保留原对象 |
| L1-002-mutability-identity | tests/test_pipeline.py:243 | 相等的独立记录列表不具有相同身份 |
| L1-003-slice-copy | tests/test_pipeline.py:246 | 批次浅拷贝共享内层列表，deepcopy 隔离修改 |
| L1-004-builtin-containers | tests/test_pipeline.py:249 | list 承载顺序、NamedTuple 承载记录、set 去重；管线 dict 聚合 |
| L1-005-index-slice | src/csv_report/core.py:73 | 半开切片补齐并截取两位金额小数 |
| L1-006-functions-return | src/csv_report/core.py:81 | 返回格式化金额供写 CSV 和报表继续使用 |
| L1-007-mutable-default | src/csv_report/core.py:125 | None 哨兵创建独立去重集合，允许显式传入共享集合 |
| L1-008-function-signature | src/csv_report/core.py:123 | records 仅位置、seen 仅关键字；测试拒绝错误调用 |
| L1-009-scope-nonlocal | tests/test_pipeline.py:261 | 流式处理回调用 nonlocal 更新外层消费计数 |
| L1-010-closure-late-binding | tests/test_pipeline.py:284 | 记录列选择器用默认参数固定列号，并验证延迟绑定反例 |
| L1-011-decorators-wraps | tests/test_pipeline.py:267 | 参数化追踪装饰器保留回调名称与文档字符串 |
| L1-012-comprehensions | src/csv_report/core.py:158 | 生成器表达式消费结构化表格行 |
| L1-013-iterator-protocol | tests/test_pipeline.py:300 | 记录队列实现迭代协议并在耗尽时抛 StopIteration |
| L1-014-generators-lazy | src/csv_report/core.py:114 | yield 按需读取并校验 CSV，缺失文件也延迟至消费时报错 |
| L1-015-context-managers | src/csv_report/cli.py:37 | 工作区在正常或异常退出时清理自检临时文件 |
| L1-016-exceptions-chain | src/csv_report/core.py:113 | 行级校验转成 DataError 并保留显式异常原因 |
| L1-017-class-attributes | src/csv_report/core.py:35 | 表头是类共享不可变元组，分组是各实例独立状态 |
| L1-018-slots | src/csv_report/core.py:34 | 报表行限制属性；测试继承仍声明 slots，拒绝多余属性 |
| L1-019-property | src/csv_report/core.py:58 | 分类 setter 统一规范化并拒绝空值，失败不覆盖旧状态 |
| L1-020-eq-hash | src/csv_report/core.py:128 | 不可变 NamedTuple 的相等与哈希契约支持完整记录去重 |
| L1-021-inheritance-super | tests/test_pipeline.py:333 | 注释报表行通过 super 保留初始化与基础列渲染 |
| L1-022-dataclass | tests/test_pipeline.py:345 | 冻结期望批次使用 default_factory，并验证浅冻结边界 |
| L1-023-collections | src/csv_report/core.py:144 | Counter 计数、defaultdict 汇总金额；测试 deque 提供流式队列 |
| L1-024-unpacking | src/csv_report/core.py:102 | 将规范化的三个 CSV 字段解包为日期、分类、金额 |
| L1-025-truthiness-short-circuit | src/csv_report/core.py:96 | 空行短路，不消费不必要的字段检查；全空字段同样跳过 |
| L1-026-numbers-bool | src/csv_report/core.py:77 | 拒绝 bool 冒充整数分，整数金额保证精确相加 |
| L1-027-unicode-strings | tests/test_pipeline.py:374 | 中文分类比较码点与 UTF-8 字节数，验证表格码点列宽 |
| L1-028-sorting-key | src/csv_report/core.py:151 | 显式 casefold 键排序；测试同键稳定性与原输入不变 |
| L1-029-enum-states | tests/test_pipeline.py:359 | 枚举限制测试命令状态，按 value 驱动实际 CLI 分派 |
| L1-030-main-guard | src/main.py:5 | 导入入口不启动 CLI，子进程验证导入静默 |
| L1-031-assert-invariants | src/csv_report/core.py:170 | assert 验证内部格式等宽；外部字段错误显式拒绝 |
| L1-032-lru-cache | src/csv_report/core.py:66 | 缓存纯金额解析；测试命中、未命中、清理与不可哈希实参 |
| L2-001-package-imports | src/csv_report/__init__.py:3 | 包内相对导入公开核心接口，脚本只负责 CLI 启动 |
| L2-002-pytest-basics | tests/test_pipeline.py:36 | fixture、tmp_path、参数化与异常断言覆盖输入和失败路径 |
| L2-003-typing-protocols | src/csv_report/core.py:29 | Protocol 定义结构化行接口，泛型序列与可选参数严格检查 |
| L2-004-mypy-check | build.sh:20 | mypy --strict 检查全部 src；测试错误金额类型必须被拒绝 |
| L2-005-ruff-check | build.sh:19 | ruff 覆盖 src 与 tests；测试未使用导入必须使门禁失败 |
| L2-006-logging | tests/test_pipeline.py:219 | 命名 logger 记录管线拒绝原因，验证级别过滤与固定诊断字段 |
| L2-007-argparse-cli | src/csv_report/cli.py:106 | clean、summary、report 子命令统一处理路径、帮助与缺参 |
| L2-008-subprocess | tests/test_pipeline.py:184 | 参数列表完整传递含空格路径，捕获 CLI 输出与非零状态 |
| L2-009-json | tests/test_pipeline.py:394 | 聚合结果 JSON 往返，排序键和紧凑分隔符验证确定性 |
| L2-010-pathlib-io | src/csv_report/core.py:85 | Path 上下文读取 CSV，测试文件读写与缺失文件异常 |
| L2-011-mock-boundaries | tests/test_pipeline.py:210 | mock 外部文件读取，验证报表结果与精确调用参数 |
| L2-012-package-resources | tests/test_pipeline.py:38 | importlib.resources 读取包内固定 CSV，不依赖当前目录 |
| L3-001-asyncio-timeout | tests/test_development.py:55 | gather 规范化批次，固定超时取消任务并验证 finally 清理 |
| L3-002-multiprocessing-pool | tests/test_development.py:32 | spawn Pool.map 执行真实分类规范化，结果保序且池正常退出 |
| L3-003-cprofile | tests/test_development.py:80 | cProfile 检查实际聚合函数调用次数，不比较不稳定耗时 |
| L3-004-struct-binary | tests/test_development.py:94 | 聚合行数与整数分以固定大端格式编码、解码并验证字节数 |
| L3-005-ctypes-libc | tests/test_development.py:101 | 声明 libc strlen ABI，验证分类 UTF-8 编码的字节边界 |
| L3-006-gil-cpu-work | tests/test_development.py:41 | 固定金额工作量在串行、线程和进程中结果一致，不作耗时断言 |
| L4-001-singleton | coverage: exempt | 每次 CLI 独立消费 CSV，计数和去重状态按调用隔离，没有进程全局唯一共享服务 |
| L4-002-factory-method | src/csv_report/reporting.py:ReportingJob.create_formatter、SummaryJob.create_formatter、FullReportJob.create_formatter | execute 模板调用子类工厂创建输出策略，CLI 的 summary 与 report 分别选择真实作业 |
| L4-003-abstract-factory | coverage: exempt | 仅一种文本表格及共用行适配器，没有需配套创建的多族产品 |
| L4-004-builder | src/csv_report/reporting.py:ReportBuilder.with_table、with_totals、build；FullReportFormat.format | 分步组装表格与统计页脚，缺任一部分拒绝发布；已构建报表不受 builder 后续修改影响 |
| L4-005-prototype | coverage: exempt | 逐行不可变记录与重新聚合的分组，不从可变预配置作业克隆实例 |
| L4-006-adapter | src/csv_report/core.py:ReportRow.cells；src/csv_report/reporting.py:TableFormat.format | 复用真实 Group 到 TableRow 的适配器，将整数分及计数转换成表格列而不修改领域记录 |
| L4-007-bridge | coverage: exempt | 只有标准库文本后端，不存在报表抽象与多种后端两个独立扩展维度 |
| L4-008-composite | src/csv_report/reporting.py:ReportText.render、ReportSection.render；ReportBuilder.build | 报表根组合标题、表格与嵌套页脚，叶子和子节用同一 render 接口递归生成固定文本 |
| L4-009-decorator | src/csv_report/reporting.py:ObservedRecords.__iter__；ReportingJob.execute | 保持 Iterable 接口并包装原记录流，在聚合消费时附加通知职责；测试双层包装保留原记录和惰性 |
| L4-010-facade | src/csv_report/cli.py:execute、run、self_check | 复用并重构统一入口隐藏读取校验、原子清洗和报表作业，CLI 与自检都调用同一业务门面 |
| L4-011-flyweight | coverage: exempt | 流式记录和按分类聚合没有大量共享内在状态对象；金额解析缓存不是享元池 |
| L4-012-proxy | coverage: exempt | 直接本地文件输入，没有远端接收者、权限代理或昂贵服务的延迟访问 |
| L4-013-chain-of-responsibility | coverage: exempt | 固定字段校验全部必过且失败即终止，没有多个候选处理者接手或 successor 转交 |
| L4-014-command | coverage: exempt | 单次同步 CLI 无排队、历史或撤销；原子文件发布不是可撤销接收者命令 |
| L4-015-interpreter | coverage: exempt | 固定 CSV 字段与三个 CLI 子命令，没有表达式语言、语法树或上下文求值 |
| L4-016-iterator | coverage: exempt | csv.reader 与生成器承担流遍历，没有需自定义游标的聚合容器；观察包装不冒充独立 GoF 遍历器 |
| L4-017-mediator | coverage: exempt | 单向管线及只接收通知的订阅者，没有双向同事交互网络需调停 |
| L4-018-memento | coverage: exempt | 不可变输入与重建报表，无领域对象编辑恢复历史；原子输出不是对象状态备忘录 |
| L4-019-observer | src/csv_report/reporting.py:RecordObserver.on_record、ReportTotals.on_record、ObservedRecords.__iter__ | 消费每条记录通知订阅者，报告页脚真实使用订阅统计；与分类聚合解耦且不再二次遍历输入 |
| L4-020-state | coverage: exempt | 一次性作业完成或异常，无长生命周期按状态改变行为的领域实体 |
| L4-021-strategy | src/csv_report/reporting.py:ReportFormat、TableFormat.format、FullReportFormat.format；ReportingJob.execute | 同一聚合流程切换纯表格和完整报告输出策略，完整报告复用表格策略确保列格式一致 |
| L4-022-template-method | src/csv_report/reporting.py:ReportingJob.execute；src/csv_report/cli.py:execute | 固定观察、单次聚合、创建策略、渲染顺序；子类仅覆盖工厂钩子，失败时不调用渲染 |
| L4-023-visitor | coverage: exempt | 组件树仅有 render 操作，无跨稳定节点类型的第二种审计或导出遍历，双分派没有业务落点 |
