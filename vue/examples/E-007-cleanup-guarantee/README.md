# E-007-cleanup-guarantee —— 副作用的清理保证

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-007 副作用清理保证），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

composable 里 watchEffect/订阅注册了却没登记清理：查询条件变了，
旧请求的响应回来把新结果覆盖掉（过期写入）；组件销毁后定时器还在跑；
轮播切走后旧订阅继续改状态。「副作用只注册不注销」是前端内存泄漏
与状态污染的头号来源。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-007-cleanup-guarantee
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-007-cleanup-guarantee \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：源变化触发重跑前旧副作用清理 1 次（失效路径）；
scope.stop() 后清理 2 次且 effect 不再执行（停止路径）。

## 为什么这样处理

- `watchEffect(onCleanup => ...)` 把清理注册和副作用注册写在同一处：
  两条清理路径（重新执行前、scope 停止时）框架保证都会调用，
  不需要手写「什么时候拆」的逻辑。
- effectScope.stop() 等价于组件卸载的聚合开关：SSR/测试环境里
  生命周期钩子不触发，scope 停止就是「这个作用域的所有副作用全体退场」。
- stop 后再改源，runs 不再增长：清理不只是计数，要验证副作用真的停了。

## 反例

- `watchEffect(() => { setInterval(...) })` 不存定时器 id、不注册清理：
  组件卸载后定时器继续跑，状态被僵尸副作用改写。
- 只在 onUnmounted 里清理、不在 onCleanup 里清理：源高频变化时
  旧副作用堆积到卸载才拆。
- 清理函数里再抛错不接住：清理路径的错误静默或污染主流程。
