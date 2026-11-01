# L3-010-custom-allocator

## 考点
对应 KP-RS-L3-10：global allocator 计数 Vec 扩容。计数器观测预留容量外的一次 Vec 扩容 realloc

## 易错点
把一次 `Vec::push` 当成必然触发一次分配，会让分配计数随实现细节和容量策略变化。先用 `with_capacity` 预留已知规模，再观察容量是否增长；自定义全局分配器还会影响整个进程，计数时必须隔离测试噪声并避免在 allocator 回调中再次分配。

## 延伸
项目的 `src/lib.rs` 预留了计数器示例中的 `Vec` 容量，但没有安装自定义全局 allocator，也没有为业务分配计数的需求。CLI 当前的向量增长不需要替换进程级分配器，本例只作 allocator 行为观察练习。

## 复现
TAG=latest scripts/run-example.sh rust L3-010-custom-allocator
