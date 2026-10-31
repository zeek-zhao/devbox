<!-- coverage: pending -->

# L1-010 —— 成员顺序与结构体填充

编译器不会重排结构体成员。将宽类型放前面可减少本例在当前 ABI 上的填充：`char/int/char`
为 12 字节，而 `int/char/char` 为 8 字节。
