# L4-009-decorator

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-09：用包装对象在运行时叠加职责，替代为每种组合派生一个子类。

可观察判据：装饰器继承同一组件基类并持有组件引用，两层叠加后输出固定拼接结果。

## 为什么这样写

`src/Main.java` 第 19–47 行的 `Decorator` 继承 `Component` 并持有注入的组件，
`Brackets`、`Stars` 各自调用被包装组件的 `render()` 再附加职责，
不在装饰器内部创建具体基础组件。第 49–56 行通过 `Component` 引用调用两层链。
若外层绕过内层，第二行 `*[java]*` 会失去方括号；
交换包装顺序则得到第三行 `[*java*]`，说明组合在运行时决定且顺序可观察。
第一行仍为原文本，证明包装没有改写基础对象。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-009-decorator
```
