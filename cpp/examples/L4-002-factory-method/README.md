# L4-002-factory-method


## 考点

对应 KP-L4-02：把「创建哪种具体类型」推迟到子类或工厂实现，调用方只依赖抽象产品。

可观察判据：抽象工厂基类声明 `create()` 返回 `unique_ptr<Product>`，两个子类工厂各产出不同类型，`name()` 输出固定字符串；调用方只持有基类指针。

## 为什么这样写

`main.cpp` 第 21–39 行声明抽象工厂和两个重写 `create()` 的具体工厂，没有字符串分支。
第 41–44 行的调用方只接收 `Factory*`，产品也由 `unique_ptr<Product>` 持有，实际通过基类指针调用虚函数。
若把 `TextFactory::create()` 改成创建 `JsonParser`，第二行 `text parser` 会变成 `json parser`；去掉抽象接口的虚派发则无法编译。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh cpp L4-002-factory-method
```
