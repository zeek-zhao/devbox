# L4-012-proxy

<!-- coverage: exempt Api.create 直接拥有本地内存服务，无远程 Api、延迟加载或访问授权目标；HttpExchange 到 DTO 是协议适配而非透明代理 -->

## 考点

对应 KP-JV-L4-12：用代理对象控制对目标对象的访问，代理与目标实现同一接口。

可观察判据：静态代理实现同一接口并持有目标，转发前后输出固定标记。

## 为什么这样写

`src/Main.java` 第 8–20 行的 `RealQuery` 与第 22–42 行的 `QueryProxy` 都实现 `Query`。
代理持有目标字段和类型安全的 `Supplier<? extends Query>`，
仅首次 `execute` 创建目标，随后复用；每次调用在转发前后打印访问计数并返回真实结果。
第 44–50 行用接口引用调用两次，构造计数从 0 变为 1，夹在标记之间的 target 行来自目标方法。
若在代理构造器里创建目标，第一行变为 1；若每次创建，最后一行变为 2。
若不转发，两个 target 行消失且返回结果不符；若丢失后置步骤，两个 after 行消失。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-012-proxy
```
