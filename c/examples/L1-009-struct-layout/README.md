<!-- coverage: pending -->

# L1-009 —— 结构体大小与 offsetof

用 `<stddef.h>` 中的 `offsetof` 打印各成员偏移，并与 `sizeof` 一起观察当前 ABI 的
结构体布局和对齐填充。
