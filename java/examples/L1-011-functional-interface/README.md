# L1-011-functional-interface

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-11：函数式接口可由匿名类或 lambda 实现。
输出显示 lambda 使用外围对象的状态，而匿名类使用自己的实例状态，即可观察 this 绑定差异。

## 易错点
lambda 中 this 不指向独立回调对象，因为它沿用外围上下文；需要独立实例状态时用匿名类或具名类。
要表达独立回调状态时，选匿名类或具名类，不要把 lambda 当作匿名类的简写。

## 延伸
为词项过滤定义带类型的函数式接口，并比较匿名类与 lambda 的可读性。
继续练习 default 方法、接口组合与 `Predicate` 等标准函数式接口。

## 复现
TAG=latest scripts/run-example.sh java L1-011-functional-interface
