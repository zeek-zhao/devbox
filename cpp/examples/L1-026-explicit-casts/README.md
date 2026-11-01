# L1-026-explicit-casts


## 考点
对应 KP-L1-26：按目的选择显式 cast，运行后可观察数值转换、上行转换及对象修改。
错误的多态下行转换必须由 `dynamic_cast` 检出空指针；字节视图只展示用途，不输出地址。

## 易错点
`const_cast` 修改真正 const 对象会导致未定义行为，因此这里只通过引用修改原本可变的对象。
`reinterpret_cast` 不会修复布局或别名问题；多态下行转换后先判空再使用。

## 延伸
可进一步用 `std::span` 描述有长度的字节范围，并比较不同转换对类型安全的影响。
在序列化或映射文件代码中，应明确对象表示、对齐与生命周期边界。

## 复现
TAG=latest scripts/run-example.sh cpp L1-026-explicit-casts
