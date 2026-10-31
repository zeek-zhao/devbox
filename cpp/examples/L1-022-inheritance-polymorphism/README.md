# L1-022-inheritance-polymorphism


## 考点
对应 KP-L1-22：基类指针调用虚函数时，派发到派生类的重写实现。
看到静态类型为 `Base*`、调用结果为 `Derived`，说明掌握运行时多态。

## 易错点
签名不匹配可能隐藏基类函数而不是重写它，导致多态调用仍执行基类版本。
使用 `override` 让编译器检查重写关系，并通过基类引用或指针调用。

## 延伸
研究纯虚函数与抽象基类如何表达接口，以及虚函数表带来的运行时派发。
比较静态多态（模板）与运行时多态在扩展方式和成本上的区别。

## 复现
TAG=latest scripts/run-example.sh cpp L1-022-inheritance-polymorphism
