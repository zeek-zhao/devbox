# L1-011-container-selection

<!-- coverage: pending -->

## 考点
对应 KP-L1-11：按操作需求选择标准库容器。
同一批键值数据分别尾部追加到 `vector` 并线性查找、插入 `map` 并按键查找；两者结果一致说明语义相同。

## 易错点
`vector` 的查找需要扫描元素，适合顺序访问与尾部追加；不要把它误认为按键直接定位。
`map` 维护键序并提供键查找；容器应依据操作需求选择，而非只看名称或单次结果。

## 延伸
将数据规模和查询需求纳入设计，比较 `map` 与 `unordered_map` 的复杂度和键序保证。
对需要两端插入的数据，进一步评估 `list` 的操作特性及其迭代访问代价。

## 复现
TAG=latest scripts/run-example.sh cpp L1-011-container-selection
