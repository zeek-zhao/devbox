# L4-023-visitor

<!-- coverage: exempt 业务实体只有一种 Item，无异构对象树；封闭 Reply 已由穷尽模式 switch 编码，不存在需要双分派扩展的实体操作矩阵 -->

## 考点

对应 KP-JV-L4-23：把作用于对象结构的操作从元素类中分离，新增操作不改元素。

可观察判据：元素实现 `accept`，两个访问者对两个元素四种组合输出固定标签。

## 为什么这样写

`src/Main.java` 的 `Element` 声明 `<R> R accept(Visitor<R> visitor)`，
`Text`、`NumberNode` 的实现均执行 `return visitor.visit(this)`。
`this` 的具体静态类型选择对应重载，再动态分派给访问者，这是双重分派。
两个元素只保存数据与接受访问者，不含渲染或测量操作。
`Render` 实现 `Visitor<String>`，`Measure` 实现 `Visitor<Measurement>`，
调用方分别接收真实的 `String` 与 `Measurement`，没有 `Object` 或强转。
`main` 通过 `List<Element>` 遍历四种组合，标签与数据由对应访问方法生成。
如果某个 `accept` 不再转交访问者，相应两行不会正确生成；
如果测量只返回固定值，`measure/text: 4`、`measure/number: 2` 无法同时正确。
新增操作只需新增访问者；新增元素则必须同步扩展访问者接口与实现。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-023-visitor
```
