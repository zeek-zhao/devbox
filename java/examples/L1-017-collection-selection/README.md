# L1-017-collection-selection

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-17：按访问方式与排序需求选择 List、Map 实现。
输出观察 ArrayList 索引访问、LinkedList 两端操作、HashMap 键覆盖查找及 TreeMap 有序遍历。

## 易错点
HashMap 输出顺序可能变化，因为它不保证排序；需排序时选 TreeMap，随机访问选 ArrayList、两端操作选 LinkedList，不用计时证明选型。
不要依赖 HashMap 的遍历顺序；只在确实需要排序时使用 TreeMap。

## 延伸
比较 HashMap 键的 `equals` 与 `hashCode` 契约，以及 TreeMap 比较器的相等判定。
为文档列表选择数据结构时，结合随机访问、队列操作和键查找需求。

## 复现
TAG=latest scripts/run-example.sh java L1-017-collection-selection
