# L4-005-prototype

<!-- coverage: exempt Item 是仅含 ID/name 的不可变 record，新建必须由事务分配新 ID；克隆现有实体会复制唯一键，快照直接复制不可变值即可 -->

## 考点

对应 KP-JV-L4-05：通过克隆已有实例创建新对象，避免重复执行昂贵构造。

可观察判据：实现 `Cloneable` 并重写 `clone()`（或拷贝构造器），副本的引用字段与原对象不共享。

## 为什么这样写

`src/Main.java` 第 14–16 行的 `Index(Index prototype)` 是判据允许的拷贝构造器，
用新 `ArrayList` 复制可变字段；元素是不可变 `String`，无需继续复制元素。
第 27–37 行比较对象及字段引用，先改副本检查原件，再改原件检查副本，验证双向隔离。
若拷贝构造器直接赋值 `prototype.terms`，第二行变为 `false`，
第三行包含 `copy-only`，第四行还会包含 `original-only`。
普通构造路径的计数为 1，说明复制没有再次走初始化路径；不依赖耗时来证明。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-005-prototype
```
