# L2-002-cargo-modules


## 考点
对应 KP-RS-L2-02：拆分多文件模块，并显式控制 crate 内成员可见性。
看到根模块逐层声明子模块、公开 API 可调用且内部辅助项保持受限，说明掌握了模块边界。

## 易错点
子模块成员不会自动对父模块公开，直接使用未声明或不可见的路径会解析失败。
逐层声明模块，并只对需要的父级显式公开成员；此例使用 `pub(super)` 限定范围。

## 延伸
把记录解析与格式化拆到各自模块，再由库根模块提供稳定 API。
比较 `pub(super)`、`pub(crate)` 与 `pub` 的可见范围。

## 复现
TAG=latest scripts/run-example.sh rust L2-002-cargo-modules
