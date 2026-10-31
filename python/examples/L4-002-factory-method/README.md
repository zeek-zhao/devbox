# L4-002-factory-method

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-02：把「创建哪种具体类型」推迟到子类或工厂实现，调用方只依赖抽象产品。

可观察判据：用 `@abstractmethod` 声明 `create()`，两个子类工厂返回不同产品类实例，`isinstance` 检查通过且 `name()` 输出固定值。

## 为什么这样写

代码位置：`main.py:20-33` 定义工厂体系，`main.py:36-51` 通过抽象接口调用并检查产品。

`main.py` 的 `ParserFactory.create()` 是抽象方法；两个子类的
`return JsonParser()` / `return CsvParser()` 行负责创建具体实例。
`describe(factory: ParserFactory)` 仅通过抽象工厂取产品、通过 `Product.name()` 调用，
具体类型检查留在演示入口。若工厂返回类而非实例，`abstract product: True`
会变为 `False`，`name()` 调用也会报错；若两个工厂返回同种产品，
`name: csv` 和 `different types: True` 会变化。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-002-factory-method
```
