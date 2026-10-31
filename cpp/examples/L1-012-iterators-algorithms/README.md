# L1-012-iterators-algorithms

<!-- coverage: pending -->

## 考点
对应 KP-L1-12：用迭代器连接容器与 `<algorithm>`，并判断容器修改后的迭代器失效。
排序、查找由标准算法完成；擦除后展示剩余元素并重新获取 `begin()` 的值，证明没有使用失效迭代器。

## 易错点
对 `vector` 执行擦除会使被删位置及其后的迭代器失效；解引用旧迭代器会导致未定义行为。
擦除后应依据容器规则判断失效范围，后续访问重新获取迭代器，切勿依赖旧位置。

## 延伸
检查 `vector::insert` 在扩容与未扩容时的迭代器失效规则。
练习 `remove_if` 与 `erase` 配合，并区分算法移动元素和容器真正缩短的阶段。

## 复现
TAG=latest scripts/run-example.sh cpp L1-012-iterators-algorithms
