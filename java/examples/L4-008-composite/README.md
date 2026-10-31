# L4-008-composite

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-08：把叶子与容器统一成同一接口，递归组合后可整体操作。

可观察判据：组件接口由叶子与容器共同实现，递归输出固定顺序。

## 为什么这样写

`src/Main.java` 第 5–36 行的 `Leaf` 与 `Group` 共同实现 `Component.print`，
容器持有 `List<Component>`，按插入顺序调用子组件，不区分叶子和容器。
第 38–42 行组装含嵌套组的树，只经根组件接口发起一次打印。
若去掉 `Group.print` 的递归调用，第二至第六行都会消失；
若 `add` 拒绝组节点，第三至第五行无法出现，甚至在构树阶段失败。
缩进体现真实递归深度，尾部叶子 d 验证递归返回后继续访问兄弟节点。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-008-composite
```
