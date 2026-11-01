# Java REST 服务：用例覆盖表

声明 `java/examples/` 全部 51 个目录（含 hello），无 pending。
落点相对于 `java/project/`；每个 ID 在对应操作或紧邻注释上单独标记。
业务实现、集成断言及构建探针共同覆盖；测试专用 JNI 不参与 runtime 服务。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/devbox/rest/SelfCheck.java:15 | 自检验证 JDK 21，随后直接执行 record DTO 请求序列 |
| L1-001-reference-values | src/SelfTest.java:110 | DTO 列表别名可见修改，方法内重新绑定不替换调用方引用 |
| L1-002-identity-equality | src/SelfTest.java:97 | 独立 name 字符串身份不同但内容相等 |
| L1-003-equality-contract | src/SelfTest.java:105 | 相等 Item 的散列一致，在 HashSet 中去重 |
| L1-004-string-pool | src/SelfTest.java:98 | name 驻留与 concat 新值不改变原输入 |
| L1-005-string-builder | src/devbox/rest/Json.java:59 | StringBuilder 循环序列化 JSON 转义字符 |
| L1-006-numeric-boxing | src/devbox/rest/RestService.java:61 | ID 显式检查加法溢出，不产生负数键 |
| L1-007-array-boundaries | src/Main.java:49 | 有界 String[] 遍历，选项取值前检查数组末尾 |
| L1-008-class-initialization | src/devbox/rest/Json.java:9 | 共享静态 final 正则仅初始化一次，Cursor 保存独立解析状态 |
| L1-009-dispatch-overloads | src/EngineeringTest.java:52 | Lookup 引用派发 Binary 重写，相邻断言按静态参数类型选择重载 |
| L1-010-interface-methods | src/devbox/rest/Api.java:38 | 默认 health 方法被业务实例继承，Api.create 静态工厂公开实现边界 |
| L1-011-functional-interface | src/devbox/rest/RestService.java:20 | 函数式 Route 为路由表 lambda 和方法引用提供目标类型 |
| L1-012-enum-switch | src/devbox/rest/RestService.java:98 | Verb 枚举和带 yield 的 switch 表达式解析 HTTP 方法 |
| L1-013-var-inference | src/Main.java:15 | 带初始化器的 var 推断 CLI Options 类型 |
| L1-014-generic-safety | src/devbox/rest/RestService.java:112 | 强类型 List Item 从 Map 值构造快照，无原始类型或强制转换 |
| L1-015-type-erasure | src/SelfTest.java:120 | Item 与 String 泛型列表运行时类相同，随后反射检查 API 泛型签名 |
| L1-016-wildcard-pecs | src/SelfTest.java:147 | DTO extends 源向 super 目标传输，保持类型安全 |
| L1-017-collection-selection | src/devbox/rest/RestService.java:13 | ConcurrentHashMap 按 ID 查询，与排序后的列表快照各司其职 |
| L1-018-iteration-views | src/devbox/rest/RestService.java:113 | 比较器排序后返回不可变快照，测试区分只读视图和快照 |
| L1-019-lambda-method-reference | src/SelfTest.java:255 | lambda 捕获稳定 minimum，Item::name 映射异步写入后的快照 |
| L1-020-stream-pipeline | src/SelfTest.java:257 | 终止操作触发惰性流水线，随后验证不可二次消费 |
| L1-021-optional-fallback | src/devbox/rest/RestService.java:81 | Optional.map 与惰性 orElseGet 将缺失 ID 转成 404 |
| L1-022-exception-categories | src/Main.java:36 | checked IOException 必须在边界捕获，与前面的 unchecked 输入错误区分 |
| L1-023-custom-exceptions | src/devbox/rest/ValidationException.java:4 | 自定义输入领域异常，构造器保留解析失败 cause |
| L1-024-resource-closing | src/devbox/rest/HttpApp.java:78 | try-with-resources 关闭 HTTP 请求流，响应流亦受保护 |
| L1-025-finally-return | src/devbox/rest/RestService.java:52 | finally 只解锁，不覆盖业务返回或掩盖异常 |
| L1-026-record-model | src/devbox/rest/Api.java:64 | Item record 构造校验 ID 和 name，值相等且组件均不可变 |
| L1-027-sealed-pattern-switch | src/devbox/rest/RestService.java:121 | sealed Reply 许可类型的穷尽模式 switch 序列化响应 |
| L1-028-reflection-access | src/SelfTest.java:130 | 私有 find 默认访问失败后显式开放，缺失方法另行拒绝 |
| L1-029-thread-runnable | src/SelfTest.java:188 | start 与直接 run 并发写入，join 后核对数量并交回工作线程异常 |
| L1-030-synchronized-counter | src/devbox/rest/RestService.java:136 | 同一 monitor 保护请求计数读改写，双线程测试精确计数 |
| L1-031-volatile-publication | src/devbox/rest/RestService.java:17 | volatile ready 在响应完成后发布状态，读线程验证已写入 DTO |
| L1-032-executor-future | src/SelfTest.java:210 | 固定线程池 Future.get 带期限收集结果和任务异常 |
| L1-033-null-boundaries | src/devbox/rest/Api.java:53 | 请求构造器 requireNonNull 拒绝空输入，测试含可空比较 |
| L2-001-packages-classpath | src/Main.java:21 | 默认入口从 devbox.rest 包调用公开服务，构建按包根输出 |
| L2-002-compile-bytecode | build.sh:8 | release 21、全警告视为错误编译，并用 javap 验 major 65 |
| L2-003-executable-jar | build.sh:9 | Main-Class 和完整包树打包为可独立运行的 app.jar |
| L2-004-api-javadoc | src/devbox/rest/Api.java:14 | handle 的参数、结果及异常 Javadoc，构建以 doclint 严格生成 |
| L2-005-assert-harness | src/SelfTest.java:36 | 强制启用 assert，注入失败与关闭断言均由构建验证非零退出 |
| L2-006-standard-logging | src/devbox/rest/HttpApp.java:35 | 标准 Logger 使用固定无时间格式的 stderr Handler，保留异常栈 |
| L2-007-cli-parser | src/Main.java:43 | 帮助、互斥自检、端口范围、缺值和未知选项手写解析 |
| L2-008-files-utf-eight | src/Main.java:23 | Files.readString 显式 UTF-8 读取启动种子，测试中文与缺失文件 |
| L2-009-module-layers | src/devbox/rest/Api.java:7 | 跨包公开业务接口，包内实现不依赖控制台和进程退出 |
| L2-010-error-protocol | src/Main.java:38 | 进程边界将输入错误和 IO 错误分别转换为退出 2 / 3 |
| L2-011-jshell-experiments | src/probes.jsh:2 | jshell 固定脚本直接创建服务，编译版执行相同 CRUD 与值相等断言 |
| L3-001-concurrent-pipeline | src/SelfTest.java:205 | CompletableFuture 与固定执行器汇总并发请求，异常 cause 明确失败 |
| L3-002-virtual-threads | src/SelfTest.java:220 | 虚拟线程执行器发健康请求并验证 isVirtual 与每个 Future |
| L3-003-jvm-thread-diagnostics | src/EngineeringTest.java:110 | jcmd 采样自有已握手线程，验证 WAITING 和 parkHere 栈帧 |
| L3-004-binary-serialization | src/devbox/rest/Snapshot.java:29 | Data 流定义大端快照，往返与魔数、长度、截断错误测试 |
| L3-005-counted-benchmark | src/EngineeringTest.java:44 | 实际快照查找预热与校验和，线性 1000 次、二分不超过 10 次 |
| L3-006-jni-native | src/devbox/tests/NativeChecksum.java:5 | 加载生成头编译的 JNI ID 校验和库，测试缺库与 null 参数失败 |
| L4-001-singleton | 豁免（用例 README） | Api.create 必须建立独立内存库；进程全局单例会让测试和同进程服务实例串数据，且没有需唯一实例的可变配置 |
| L4-002-factory-method | src/devbox/rest/RestService.java:NameRoute.success、CreateRoute.success、UpdateRoute.success | 写入模板调用子类工厂制造成功响应，新增返回 201、替换返回 200，主流程不硬编码子类的成功状态 |
| L4-003-abstract-factory | 豁免（用例 README） | 服务固定使用 JDK HttpServer、内存库和 JSON 协议，不存在需要成套切换的传输/存储产品家族 |
| L4-004-builder | src/devbox/rest/ResultBuilder.java:status/contentType/body/build；RestService.encode/json | 分步装配不可变 HTTP 响应，提交前检查字段完整性、状态码和 204 空体，JSON 与纯文本分支共用构造约束 |
| L4-005-prototype | 豁免（用例 README） | Item 是仅含 ID/name 的不可变 record，新建必须由事务分配新 ID；克隆现有实体会复制唯一键，快照直接复制不可变值即可 |
| L4-006-adapter | src/devbox/rest/HttpApp.java:ExchangeRequestAdapter.read、respond | 把 JDK HttpExchange 的方法、原始路径和有界 UTF-8 请求流适配为 Api.Request，业务路由不依赖网络类型 |
| L4-007-bridge | 豁免（用例 README） | 只有一种 HTTP 传输和一种内存存储，Api 已隔离传输边界；没有需要独立扩展并交叉组合的两套实现层级 |
| L4-008-composite | src/devbox/rest/RestService.java:Router、ExactRoute.resolve、RouteGroup.resolve、routes | 管理路由组、资源路由组和精确匹配叶子通过相同接口递归解析；保留组内优先级和末尾 ID/未知路由处理 |
| L4-009-decorator | src/devbox/rest/RestService.java:ValidatedRoute.apply、dispatch、handle | 包装同一 Route 接口，在所有业务处理算法外统一把领域校验异常转成 400；非校验缺陷继续抛向 HTTP 日志边界 |
| L4-010-facade | 豁免（用例 README） | 项目已有单一 Api 业务边界，CRUD 不需协调多个独立子系统；JSON 与快照各有固定入口，再增加门面只会转发现有接口 |
| L4-011-flyweight | 豁免（用例 README） | 每条 Item 仅有唯一 ID 和短 name，无可拆分的昂贵共享内蕴状态；跨实体共享可变对象会破坏不可变快照契约 |
| L4-012-proxy | 豁免（用例 README） | Api.create 直接拥有本地内存服务，无远程 Api、延迟加载或访问授权目标；HttpExchange 到 DTO 是协议适配而非透明代理 |
| L4-013-chain-of-responsibility | 豁免（用例 README） | 请求只选择一个 CRUD 处理器，路由树仅匹配地址；没有可逐级受理、拒绝或传递业务责任的审批/中间件链 |
| L4-014-command | 豁免（用例 README） | 写入在请求事务内立即完成，服务不承诺命令排队、重放或撤销；把请求再包装成命令对象不会提供这些业务语义 |
| L4-015-interpreter | 豁免（用例 README） | 请求只含固定路径与单字段 JSON，不提供可组合表达式、查询语言或规则 DSL；JSON 字符串解码不是执行语言解释器 |
| L4-016-iterator | 豁免（用例 README） | 快照直接返回 JDK 不可变 List，现有循环由标准集合迭代器承担；没有隐藏存储布局或自定义游标遍历协议可供实现 |
| L4-017-mediator | 豁免（用例 README） | HttpApp 单向调用 Api，实体不互相通信；不存在多个对等组件交互网需要中介协调 |
| L4-018-memento | 豁免（用例 README） | Snapshot 只做可移植编码，服务无恢复或撤销端点，也不保留历史；引入 caretaker 会新增尚未承诺的回滚语义 |
| L4-019-observer | src/devbox/rest/RestService.java:RequestObserver、RequestEvents.publish、Counter.accepted、handle | 业务入口发布已接收请求，计数订阅者独立累加；400/404 仍计数，HTTP 提前拒绝和 null 不计数，保持 metrics 当前请求语义 |
| L4-020-state | 豁免（用例 README） | Item 没有生命周期状态，ready 只是首次请求完成后的单向发布标志；没有随状态改变的多组行为或可逆迁移 |
| L4-021-strategy | src/devbox/rest/RestService.java:Route.apply、dispatch、CreateRoute、routes | 路由解析选择可替换的 Route 算法，健康、指标、快照与新增处理均经统一 apply 调用；新增写入算法不是固定在调度器中 |
| L4-022-template-method | src/devbox/rest/RestService.java:NameRoute.apply、CreateRoute.save、UpdateRoute.save、itemRoute | 新增和替换共用 final 的解析校验→存储→成功响应骨架，只重写写入和响应钩子，保证无效输入不消耗 ID 或修改实体 |
| L4-023-visitor | 豁免（用例 README） | 业务实体只有一种 Item，无异构对象树；封闭 Reply 已由穷尽模式 switch 编码，不存在需要双分派扩展的实体操作矩阵 |
