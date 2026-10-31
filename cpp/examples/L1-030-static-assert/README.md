# L1-030-static-assert

<!-- coverage: pending -->

## 考点
对应 KP-L1-30：`static_assert` 在编译时检查类型约束和常量条件，断言成立后程序运行。
输出展示同一类型关系的布尔值，读者可核对编译期条件与可观察结果一致。

## 易错点
依赖运行期数据的表达式不是常量表达式，不能用于 `static_assert`；改用类型特征或常量。
约束应准确表达需求且断言保持成立，避免无关的平台假设导致无法编译。

## 延伸
可在模板中用类型特征限制参数，并学习 C++20 concepts 表达可复用的编译期约束。
逐步将错误信息清晰的静态检查加入接口边界。

## 复现
TAG=latest scripts/run-example.sh cpp L1-030-static-assert
