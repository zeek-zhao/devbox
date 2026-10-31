# Java REST 服务

纯 JDK 21：`HttpServer` 路由、手写 JSON、record DTO、sealed 响应与模式 switch、
内存 CRUD、参数校验、健康检查及集成测试。服务无第三方库，无下载步骤。

## 构建 / 运行 / 测试

在仓库根目录执行：

```bash
bash java/project/build.sh
java -jar java/project/build/app.jar --port 8080
bash java/project/check-runtime.sh
```

构建需完整 JDK 21 和 C 编译器（本地 Java 镜像已提供）。构建入口每次重新编译，
运行 `SelfTest`、工程探针和无端口自检，输出全部位于已忽略的 `build/`。
只测试集成逻辑：`java -ea -cp java/project/build/classes SelfTest`。
离线镜像构建：`docker run --rm -v "$PWD/java/project:/work" -w /work "ghcr.io/zeek-zhao/devbox-java:${TAG:-latest}" bash build.sh`。
runtime 只挂载 `build/app.jar`，不需要编译器、本地库或仓库元数据。

## 目录与分层

```text
src/Main.java                 参数与进程退出边界
src/devbox/rest/Api.java       跨包公开接口和 DTO
src/devbox/rest/RestService.java 包内业务实现、路由、事务和存储
src/devbox/rest/Json.java      单字段 JSON 解析与完整字符串转义
src/devbox/rest/HttpApp.java   HTTP 适配、固定线程池、流与生命周期
src/devbox/rest/Snapshot.java 可移植二进制快照编解码
src/devbox/rest/SelfCheck.java 固定请求序列，无网络监听
src/SelfTest.java              路由、真实 HTTP、并发、错误及值语义测试
src/EngineeringTest.java       二进制往返、查找操作数、线程诊断和文件测试
src/devbox/tests/              测试专用 JNI 快照 ID 校验和
src/probes.jsh                固定 REPL 业务实验，编译版测试同步验证
COVERAGE.md                   全部 51 个用例的实际落点
build.sh                      幂等编译、打包、文档与测试
check-runtime.sh              只读挂载、逐字比较（包括结尾换行）
```

## API 契约

默认仅监听 `127.0.0.1:8080`，不对公网开放。Ctrl-C 关闭监听和线程池。
`--help` 显示帮助；`--seed FILE` 在启动前用 UTF-8 文件内容创建首条记录。
`--self-check` 是互斥模式，不读取文件、不构造监听地址：
`java -jar java/project/build/app.jar --self-check`。

| 请求 | 返回 |
|---|---|
| `GET /healthz` | 200 `{"status":"ok"}` |
| `GET /metrics` | 200 纯文本 `requests_total N`，包含当前 metrics 请求 |
| `POST /items` | 201 `{"id":1,"name":"Ada"}` |
| `GET /items` | 200 按 ID 排序的数组 |
| `GET /items/1` | 200 单条；不存在为 404 |
| `PUT /items/1` | 200 替换 name；不存在为 404 |
| `DELETE /items/1` | 204 空响应；不存在为 404 |

写入使用 `Content-Type: application/json` 和形如 `{"name":"Ada"}` 的请求体。
必须且只能有一个 name 字段，拒绝重复字段、未知字段、尾随内容、非法 UTF-8、
裸控制字符、不配对的 Unicode 代理项。name 为 1..64 个 Unicode 字符，首字符为
字母或数字，其余允许字母、数字、空格及 `_.'"\-`。体积上限 4096 字节。
无查询参数；非法输入为 400，错误媒体类型为 415，未知路由为 404，不支持的方法为 405。
错误响应为 `{"error":"..."}`；内部缺陷为 500 并记录标准错误日志。
进程输入错误退出 2，文件/监听 IO 错误退出 3，内部缺陷保留异常并非零退出。

计数记录进入业务 handler 的所有请求；HTTP 适配层提前拒绝的请求不计数。
`ConcurrentHashMap` 保管数据，显式重入锁保护 ID 分配与 CRUD / 快照事务；
计数器使用同一个 monitor 保护复合自增，volatile 发布完成状态。
数据只在内存中，重启清空，不承诺数据库持久化。Snapshot 是独立备份编解码 API：
大端魔数 `01 02 03 04`、版本 1、数量、每条 ID 与 UTF-8 长度/内容，
拒绝重复/乱序 ID、截断、尾随字节和越界长度。

工程探针用生成的 JNI 头编译测试库，并验证缺库明确失败；该库不用于服务运行。
`jcmd Thread.print` 仅采样自有 JVM 中已握手进入 WAITING 的线程，不打印进程号或线程转储。
查找基准预热并消费校验和，验线性访问 1000 次、二分不超过 10 次，不以耗时作门槛。
HTTP 集成测试单独启动临时本地端口；runtime 自检始终只调用业务逻辑。
