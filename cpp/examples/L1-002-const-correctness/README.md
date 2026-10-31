# L1-002-const-correctness

<!-- coverage: pending -->

## 考点
对应 KP-L1-02：`const` 引用参数和 `const` 成员函数提供只读访问。
运行结果显示只读接口读到对象的值，且修改接口对 const 对象不可调用。

## 易错点
非 const 成员函数不能用于 const 对象，遗漏成员函数末尾的 `const` 会拒绝调用。
只读参数用 `const T&`，并用只读成员函数访问，不要移除对象的 const 限定。

## 延伸
为查询接口添加 const 重载，并用编译期类型特征检查接口可调用性。
继续区分“指向 const 的指针”和“自身为 const 的指针”。

## 复现
TAG=latest scripts/run-example.sh cpp L1-002-const-correctness
