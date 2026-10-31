# L1-021-defer-order-return

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-21：两个 defer 后进先出，并修改命名返回值。
看到第二个注册的 defer 先读到 5，第一个仍打印 2，调用方最终得到 6，即掌握顺序与返回时机。

## 易错点
defer 调用参数在注册时求值，而闭包引用可延后读取，混淆二者会误判输出。
需修改返回结果时使用命名返回并明确闭包捕获；先设置返回值，再执行延迟函数。

## 延伸
在查询计数收尾中用 defer 合并最终统计，断言调用方收到的数值。
为多个资源的收尾设计注册顺序，使后取得的资源先释放。

## 复现
TAG=latest scripts/run-example.sh go L1-021-defer-order-return
