# L3-002-multiprocessing-pool

<!-- coverage: pending -->

## 考点
对应 KP-PY-L3-02：用 `multiprocessing.Pool.map` 执行纯函数工作项。
固定输入按原顺序得到规范化结果且池正常退出，说明掌握了该 KP。

## 易错点
模块顶层无条件建池会在 spawn 环境递归创建子进程。
把启动逻辑放进主入口守卫，并用上下文管理器关闭进程池。

## 延伸
比较批量独立记录转换的任务粒度和序列化开销。
为工作函数补充明确的错误结果与批次重试策略。

## 复现
TAG=latest scripts/run-example.sh python L3-002-multiprocessing-pool
