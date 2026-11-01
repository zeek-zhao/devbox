

# L1-015 —— const 与指针

`const int *` 可改指针但不可经它改值；`int * const` 可改值但不可改指针；
`const int * const` 两者都不可改。对应的非法赋值应由编译器拒绝，例如
`*pointer_to_const = 1`、`const_pointer = &other` 和
`*const_pointer_to_const = 1`；本例不编译失败代码。
