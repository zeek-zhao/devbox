# E-011-deadline-cancel —— 超时与取消

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-011 超时与取消），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

批量操作没有预算：后端 hang 住后调用方无限等待，线程被占死；
或者外部想取消任务却无从下手——worker 只在结束时才看一眼标志位，
取消请求实际被无视。停止后的「已完成进度」也没有上报，调用方无法决定续跑还是重来。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-011-deadline-cancel
docker run --rm -v "$PWD":/work -w /work/c/examples/E-011-deadline-cancel \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：deadline 场景第 3 步后超时收场（code=4，
completed_steps=3）；cancel 场景第 2 步后在安全点退出（code=6，
completed_steps=2）。

## 为什么这样处理

- 停止信号分两类、各有专门错误码：TIMEOUT 是内部预算触发的自我保护，
  CANCELLED 是外部意志，混用一个码会让上游无法区分该重试还是该放弃。
- 检查点放在循环顶部（安全点）：每次迭代先看预算与取消标志，再做不可回退的工作，
  保证退出时状态一致。
- 返回 completed_steps：断点续跑、幂等重试都依赖「做到哪了」这个事实。
- 教学实现用虚拟步数时钟：输出与真实耗时解耦，断言稳定；真实代码把
  `done_steps >= budget` 换成单调时钟比较即可。

## 反例

- 阻塞调用（如无超时的 connect/read）里不设预算：协作式检查永远没机会执行。
- 收到取消后「做完当前批再退」：取消语义被稀释成建议，调用方的等待没有上界。
