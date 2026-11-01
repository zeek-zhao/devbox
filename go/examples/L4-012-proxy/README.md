# L4-012-proxy

<!-- coverage: exempt 分析器是进程内立即创建的廉价计算对象，没有远程资源、惰性加载或替身访问控制；现有包装增加完成通知，属于装饰而非代理资源访问 -->

## 考点

对应 KP-GO-L4-12：用代理对象控制对目标对象的访问，代理与目标实现同一接口。

可观察判据：代理结构体持有目标接口，调用前后打印固定标记，转发结果一致。

## 为什么这样写

结构位置：`main.go:8-19` 为目标接口与实现，`main.go:21-34` 为接口代理及前后访问控制，`main.go:36-46` 为结果与调用次数对照。

`main.go` 的 `RealQuery` 与 `LoggingProxy` 都实现 `Query.Search()`；代理字段是 `target Query`，构造函数也接收并返回接口。
`LoggingProxy.Search()` 的三步是打印 before、调用目标并保存返回值、打印 after，最后原样返回结果。
`main()` 先通过接口直接查询，再通过代理查询，比较两个实际返回值并读取真实目标的调用计数。
如果代理不转发而伪造字符串，即使 `same result` 不变，`target calls: 2` 也会变成 1；如果代理改变返回值，`proxied` 和 `same result` 两行会改变。
前后标记由串行方法调用产生，不依赖并发调度；代理只增加访问日志职责，不改变查询语义。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-012-proxy
