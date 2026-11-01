# L4-003-abstract-factory

<!-- coverage: exempt 服务固定使用 JDK HttpServer、内存库和 JSON 协议，不存在需要成套切换的传输/存储产品家族 -->

## 考点

对应 KP-JV-L4-03：一个工厂接口成组创建一族相互配套的产品，切换工厂即切换整套实现。

可观察判据：两个 `AbstractFactory` 实现成组返回配套产品，同族 `family()` 一致、跨族不同。

## 为什么这样写

`src/Main.java` 第 38–65 行的 `AbstractFactory<B, C>` 分别声明按钮与复选框创建方法，
两个实现分别绑定亮色、暗色产品类型；泛型上界保证无需 `Object` 或强转。
第 67–79 行的 `inspect` 仅通过抽象工厂和产品接口调用，真实比较同族产品的 `family()`，
`main` 再比较两个工厂产物的族名。
若暗色复选框的族名错误地改为亮色，第四行 `paired: true` 会变为 `false`；
若整个暗色族改为亮色，最后一行 `different families: true` 会变为 `false`。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-003-abstract-factory
```
