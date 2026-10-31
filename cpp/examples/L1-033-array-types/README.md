# L1-033-array-types

<!-- coverage: pending -->

## 考点
对应 KP-L1-33：对比 C 数组、编译期定长的 `std::array` 与可增长的 `std::vector`。
看到 `std::size` 保留各自长度，且传参后 `sizeof` 从整个 C 数组大小变为指针大小，即可说明掌握数组退化。

## 易错点
C 数组作为函数参数会调整为指针，函数内 `sizeof` 得不到原数组长度；在退化前用 `std::size` 取长度。
`std::array` 长度固定而 `std::vector` 可动态增长；按数据大小是否运行期变化选择容器。

## 延伸
可以进一步用 `std::span` 将连续数据和长度一起传给函数，避免裸指针丢失长度。
还可比较固定容量缓冲区与动态容器在接口和内存分配上的差别。

## 复现
TAG=latest scripts/run-example.sh cpp L1-033-array-types
