<!-- coverage: pending -->

# L1-007 —— 数组传参退化为指针

数组传给函数后，形参是指针，所以函数中的 `sizeof(arr)` 是指针大小；函数外的
`sizeof(values)` 则是整个数组大小。`int *arr` 明确写出调整后的形参类型。
