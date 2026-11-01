# L4-002-factory-method


## 考点

对应 KP-JV-L4-02：把「创建哪种具体类型」推迟到子类或工厂实现，调用方只依赖抽象产品。

可观察判据：抽象工厂类声明 `abstract Product create()`，两个子类返回不同实现；用父类型变量接收后 `name()` 输出固定值。

## 为什么这样写

`src/Main.java` 第 20–36 行的 `Factory<P extends Product>` 用真实泛型将判据中的返回类型细化为
`abstract P create()`；`JsonFactory`、`TextFactory` 分别实现创建步骤，无静态分支或强转。
第 38–48 行用抽象工厂类型接收两个子类，泛型方法 `show` 将产物存入 `Product` 父类型变量，
再动态调用 `name()`。若第二个工厂也返回 JSON 产品，类型检查先失败；
若将其合法改为创建 JSON 的工厂，第二行会由 `product: text` 变成 `product: json`。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-002-factory-method
```
