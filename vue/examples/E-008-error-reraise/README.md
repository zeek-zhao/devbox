# E-008-error-reraise —— onErrorCaptured 的重抛决策

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-008 onErrorCaptured 重抛决策），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

中间层 onErrorCaptured 里"看了一眼就 return false"：错误从此消失，
app 级监控与上报完全失明——"处理过"和"吞掉"只差一个返回值。
反过来想换个说法再往上抛，又发现行为出乎意料（新错误带着
errorCaptured hook 的 info 进 app 级，原错误也还在传播）。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-008-error-reraise
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-008-error-reraise \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：swallow 模式 app-reports=0（全盲）；
passthrough 原错误原样到达 app 级；reraise 模式 app 级收到两条
（包装后的新错误 info=errorCaptured hook + 继续传播的原错误）。

## 为什么这样处理

- 返回 false 的唯一正当理由是"这一层真的处理掉了"（降级/重试/兜底成功）；
  只是"看见了"不算处理（与 shell 轨 E-008 同一纪律）。
- 原样放行用 `return undefined`：错误对象原引用继续上抛，
  身份、context 标注（E-006）都保留。
- 钩子里抛新错误的行为是实测结论：Vue 把钩子里抛出的错误以
  `info=errorCaptured hook` 送进 app 级，且原错误继续传播——
  想在中间层换一种错误上报时，要知道代价是"app 级看到两条"。

## 反例

- 钩子里记了日志就 return false：监控全盲，假绿（S-03 同型）。
- 不加判断地重抛包装错误：app 级收到重复上报，指标翻倍失真。
- 三层组件层层 return false：错误在最内层就被吞干净，出事找不到现场。
