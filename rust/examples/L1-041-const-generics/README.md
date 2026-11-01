# L1-041-const-generics

## 考点
对应 KP-RS-L1-41：数组长度 const 泛型。相同泛型函数接收不同长度数组并输出长度和值

## 易错点
把数组长度写成运行时 `usize` 参数，不能让函数在类型层面区分 `[T; 2]` 和 `[T; 3]`，也无法用同一个泛型签名保留长度信息。用 `const N: usize` 把长度纳入类型参数；但这不意味着任意运行时长度都能成为编译期常量。

## 延伸
项目的 `src/lib.rs` 定义了固定的 `OPERATIONS` 和 `WORKERS` 常量，但没有接收多种编译期数组长度的通用函数。CLI 的输入规模是运行时决定的，项目里没有真正需要 const generics 的地方，本例只作类型级长度练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-041-const-generics
