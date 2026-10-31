# L1-010-stl-containers


## 考点
对应 KP-L1-10：`vector::push_back` 追加元素，按迭代访问可见插入后的顺序。
有序集合的 `insert`、`find`、`erase` 分别展示插入、查找和删除结果。
观察重复键不增加元素、查找命中及删除计数，即可验证这些接口语义。

## 易错点
`push_back` 会追加到末尾，不会在指定位置插入元素。
关联容器的 `insert` 遇到已存在的键不会再添加副本，`erase` 会返回删除数量。
查看操作返回值和修改后的内容，确认操作是否真正改变了容器。

## 延伸
练习用 `vector` 保存可遍历的序列，并观察插入、删除前后的元素位置。
进一步学习容器修改时迭代器及元素引用的失效规则。

## 复现
TAG=latest scripts/run-example.sh cpp L1-010-stl-containers
