# L1-002-zero-values


## 考点
对应 KP-GO-L1-02：观察短声明和 `var` 声明，以及基本类型、指针、slice、map、struct 的零值。
看到它们输出各自规定的零值，并且初始化后的 map 可写入，说明掌握声明与初始化。

## 易错点
局部变量不能省略声明；零值 map 不能写入会 panic。
先用 `make` 初始化需要写入的 map，再执行赋值。

## 延伸
用零值初始化索引配置与空查询结果，并验证未设置字段的默认状态。
比较适合直接使用零值的类型与需要显式初始化的容器。

## 复现
TAG=latest scripts/run-example.sh go L1-002-zero-values
