# L1-029-directional-channels

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-29，生产函数只返回 `<-chan int`，入队函数和消费函数分别约束发送、接收能力。
看到双向 channel 可传入单向参数并按签名完成传递，即可判断方向约束已掌握。

## 易错点
双向 channel 可以传给发送或接收方向的参数，但单向 channel 不能反转成双向使用。
在函数签名上只暴露所需方向，避免调用方意外执行另一类操作。

## 延伸
把单向 channel 用于任务队列接口，让生产者和消费者拥有各自最小的操作能力。
进一步用多个消费者共享只读输入，并由生产者负责关闭队列。

## 复现
TAG=latest scripts/run-example.sh go L1-029-directional-channels
