# E-013-error-observability —— 生产报错的结构化上报

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-013 生产报错结构化上报），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

生产前端的错误处理是一句 `console.error(err)`：控制台关了就什么都没留下；
上报日志里只有 message，不知道错在哪个组件、是渲染炸了还是异步炸了——
"哪个页面的哪个组件失败率最高"这种最基本的分桶都做不了。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-013-error-observability
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-013-error-observability \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两条结构化上报各带组件名、消息与位置类别，
汇总 reports=2、字段 3 个。

## 为什么这样处理

- `app.config.errorHandler` 是全应用唯一的错误汇聚点：render 炸、
  setup 炸、异步 setup 拒绝都汇到这里，上报逻辑只写一份。
- 上报记录是结构化三元组（component/message/info）：component 来自
  组件的 name 选项（所以组件必须命名），info 是 Vue 官方的位置类别
  （E-001 的分类体系），按组件分桶的错误率报表由此而来。
- 匿名组件上报为 `-`：字段永远在，值为空也是信息
  ——"该命名了"变成可统计的指标。

## 反例

- 上报里只有 `String(err)`：无法分桶，也丢栈。
- 每个组件自己 try/catch 上报：漏一处少一处，格式还各自漂移。
- 上报后 return true 继续默认告警：控制台与上报双轨，
  告警噪音淹没有效信息。
