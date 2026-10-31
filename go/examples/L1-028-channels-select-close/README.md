# L1-028-channels-select-close


## 考点
对应 KP-GO-L1-28，观察无缓冲握手、缓冲值在关闭后被 range 收尽。
关闭后 comma-ok 为 false，select 对就绪和空 channel 分别走接收与 default，即可验证掌握。

## 易错点
向已关闭 channel 发送会 panic，关闭后继续接收则得到零值；因此只由发送方负责关闭。
要区分合法数据与关闭后的零值，使用 comma-ok 检查接收状态。

## 延伸
将派发 channel 用于解析任务，并由生产方在提交完任务后关闭它。
练习用 select 同时监听多个输入 channel，并明确处理退出信号。

## 复现
TAG=latest scripts/run-example.sh go L1-028-channels-select-close
