# L1-018-nil-interfaces


## 考点
对应 KP-GO-L1-18：区分 nil 接口值与装有 nil 指针的接口值。
看到接口与 nil 比较为 false，而类型断言取回 nil 指针，说明掌握了动态类型和值。

## 易错点
接口含有动态类型时不等于 nil，即使它保存的指针值为 nil。
返回错误时避免直接返回 typed nil 指针；确认接口本身确实为 nil。

## 延伸
为存储适配器实现错误返回，并验证 nil 接口与 typed nil 的调用方表现。
设计构造和错误路径，确保不会意外暴露 typed nil。

## 复现
TAG=latest scripts/run-example.sh go L1-018-nil-interfaces
