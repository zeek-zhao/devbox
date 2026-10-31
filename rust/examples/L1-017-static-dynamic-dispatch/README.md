# L1-017-static-dynamic-dispatch

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-17：对比泛型静态分发与 `dyn Trait` 动态分发。
看到泛型函数分别接收不同具体类型，且同一 trait 对象集合调用到各自实现，说明分发方式清晰。

## 易错点
会把不同具体类型直接放入同一泛型容器而类型不一致；需要异构集合时使用 trait 对象并满足对象安全约束。
集合元素以 `&dyn Render` 统一接口，trait 方法不依赖泛型返回类型等非对象安全特性。

## 延伸
在文档解析器接口中对比编译期确定具体类型和运行期选择解析器。
需要异构策略集合时使用 trait 对象，并留意对象安全要求。

## 复现
TAG=latest scripts/run-example.sh rust L1-017-static-dynamic-dispatch
