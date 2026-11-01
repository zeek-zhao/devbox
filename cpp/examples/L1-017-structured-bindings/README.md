# L1-017-structured-bindings


## 考点
对应 KP-L1-17：分别拆解 `std::tuple` 和聚合体，并比较值绑定与引用绑定。
看到值绑定修改副本、`auto&` 修改原对象，即说明理解了绑定的对象关系。

## 易错点
`auto [a, b]` 通常复制被拆解对象的元素，修改绑定变量不会更新原对象。
需要修改原对象时显式使用 `auto& [a, b]`，并确认原对象仍然存活。

## 延伸
可进一步比较 `const auto&` 与 `auto&&` 绑定的类型和适用场景。
试着用结构化绑定遍历映射表中的键值对。

## 复现
TAG=latest scripts/run-example.sh cpp L1-017-structured-bindings
