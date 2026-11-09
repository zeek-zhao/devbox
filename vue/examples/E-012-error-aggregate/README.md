# E-012-error-aggregate —— 并行加载的失败聚合

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-012 并行加载失败聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

仪表盘并行拉 3 个数据源用 `Promise.all`：第一个失败就把整个页面打死，
另外两个明明成功的数据也被丢弃；修好一个再刷新，又撞出下一个失败——
失败清单永远一次只显示一个。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-012-error-aggregate
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-012-error-aggregate \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：成功源保留值，两个失败源各带 reason 码，
汇总 ok=1 failed=2，末行是完整失败原因清单。

## 为什么这样处理

- `Promise.allSettled` 不短路：每个数据源的结局都保留，
  一个失败不遮蔽其他成功，也不遮蔽另一个失败。
- 失败聚合不是吞掉：末行汇总 + 非零语义（此处以 reasons 清单呈现）
  交给上层决定降级策略——部分数据可用时渲染部分页面，
  全部失败时才整体报错。
- reason 是结构化 code（E_OFFLINE/E_QUOTA），不是 message 文本：
  聚合清单可以直接按码分派后续动作（重试哪个、上报哪个）。

## 反例

- `Promise.all` 一失败全丢：成功数据被连坐，用户看整页报错。
- allSettled 之后只看第一个 rejected：失败清单被截断，修复轮次翻倍。
- 把失败 reason 拼成一句文案：分派逻辑退化为字符串匹配（E-003 的坑）。
