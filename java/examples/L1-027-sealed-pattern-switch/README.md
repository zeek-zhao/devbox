# L1-027-sealed-pattern-switch

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-27：sealed/permits 限定子类型，类型模式 switch 覆盖许可类型。
看到两个许可分支分别匹配，null 分支输出固定标签，即说明掌握穷尽与空值处理。

## 易错点
新增子类型会让 switch 不穷尽，而 null 输入也有独立约束；两者不能混为一谈。
列全许可类型，并显式处理或拒绝 null；本例使用 Java 21 正式功能，不启用预览。

## 延伸
把查询条件建模为封闭类型，评估添加新分支时编译器如何提示所有调用点。
将 null 分支改成显式拒绝，比较两种 API 对空输入的契约。

## 复现
TAG=latest scripts/run-example.sh java L1-027-sealed-pattern-switch
