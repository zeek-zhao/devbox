# L3-002-thread-synchronization


## 考点
对应 KP-L3-02：用互斥锁保护共享状态，并用条件变量完成线程握手。
看到两个线程都完成、主线程 join 后按序打印固定结果，说明同步与结果收集正确。

## 易错点
条件变量可能虚假唤醒；用持锁谓词等待，而不是无条件 wait 一次。
在线程中直接输出会受调度影响；写入各自固定数组槽位，join 后排序并由主线程打印。

## 延伸
将单次握手扩展为多个生产者与消费者，并用谓词表达队列非空和未关闭条件。
用 ThreadSanitizer 检查共享状态的访问是否始终受互斥锁保护。

## 复现
TAG=latest scripts/run-example.sh cpp L3-002-thread-synchronization
