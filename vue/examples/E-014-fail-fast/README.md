# E-014-fail-fast —— 启动前置校验与快速失败

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-014 启动前置校验快速失败），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

构建产物里的环境配置（API 地址、令牌）没注入：应用照常启动、
页面照常渲染，用户点第一个按钮才炸——失败从"构建时 0 秒拦截"
退化成"运行时用户眼前爆炸"，报错还只是 undefined 的间接症状。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-014-fail-fast
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-014-fail-fast \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：缺 DEVBOX_API_URL 时 created=false 并指名缺失项
（code=E_ENV_REQUIRED field=DEVBOX_API_URL）；环境齐备时应用正常创建。

## 为什么这样处理

- 校验集中在 `REQUIRED_ENV_KEYS` 清单 + 一个函数里，createApp 之前执行：
  缺一个配置就不创建应用——"带病启动"被从根上禁止。
- 校验错误用结构化错误（E-002）：code 定策略（这是部署问题，修产物，
  重试无意义）、field 直接指名缺失键，CI/部署日志可 grep。
- 必需项清单是一份显式契约：新增必需配置时改清单，遗漏在启动期即红。

## 反例

- 用 `env.API_URL || 'http://localhost'` 兜底：缺失被默认值掩盖，
  生产环境静默打到 localhost。
- 校验散落在各个模块里：有的查了有的没查，失败时点随机。
- 只校验不指名：报 "env error"，部署的人挨个变量猜。
