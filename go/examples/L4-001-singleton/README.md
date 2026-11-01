# L4-001-singleton

<!-- coverage: exempt 网关允许同一进程创建多个独立 worker pool 与令牌桶，测试也并行创建实例；进程唯一实例会错误共享限流与关闭状态 -->

## 考点

对应 KP-GO-L4-01：同一类型全局只存在一个实例，所有取用点看到同一份状态。

可观察判据：用 `sync.Once` 包住初始化；两个 goroutine 并发取实例后指针相等，初始化函数只执行一次（打印 `init calls: 1`）。

## 为什么这样写

结构位置：`main.go:18-24` 为延迟初始化，`main.go:27-39` 为双 goroutine 取用与等待，`main.go:41-45` 为实际比较和共享状态观察。

`main.go` 的 `GetConfig()` 用 `once.Do` 包住计数与实例赋值两行，包级指针最初为 nil，真正取用时才初始化。
`main()` 启动两个 goroutine，经同一开始信号取用，分别写入数组不同位置；`wg.Wait()` 后才比较指针、读取计数及串行修改共享状态。
如果每次取用都构造新对象，`same instance: true` 会变成 false，`init calls: 1` 会变成 2，第二个实例的 `shared mode` 也不会是 production。
开始信号不保证调度先后，也不需要保证；所有打印都发生在等待结束后，配置修改不与 goroutine 并发。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-001-singleton
