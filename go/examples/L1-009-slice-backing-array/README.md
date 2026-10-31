# L1-009-slice-backing-array


## 考点
对应 KP-GO-L1-09：分别观察有剩余容量和容量已满时 append 的底层数组行为。
前者可从旧 slice 看到新元素，后者修改新 slice 不影响旧 slice，说明掌握共享与分离。

## 易错点
append 是否扩容取决于容量，不能根据 slice 长度猜测底层数组是否共享。
先检查 cap，并用各自独立的输入断言追加后的共享或分离现象。

## 延伸
在倒排表追加与缓冲区增长中检查容量，再决定是否需要复制隔离。
测试边界容量下的 append，避免依赖运行时扩容倍数。

## 复现
TAG=latest scripts/run-example.sh go L1-009-slice-backing-array
