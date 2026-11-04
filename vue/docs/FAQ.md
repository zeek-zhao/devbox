---
track: vue
guide: G5
dimensions: [D2, D5, D8]
level: P1
status: draft
links: [开发指南.md, 工具指南.md, 知识点清单.md]
examples: [L0-hello, L1-002-ref-vs-reactive, L2-004-unit-test-harness]
---

# Vue FAQ（G5）

> 一问一答，先结论、再一步命令、最后给「详见」。每条 50–200 字。
> G3 问题指南（按问题域的长排查）本轨道尚未建（M8 补齐），本篇先承接高频短问。

## 环境与镜像

### Q: devbox-vue 里的 Node / Vue / prettier 是什么版本？想升级去哪改？

A: 版本只有一份真本：`images/versions.env`——`${NODE_VERSION}`、`${VUE_VERSION}`
（vue 与 @vue/compiler-sfc、@vue/server-renderer 必须三者同版）、
`${PRETTIER_VERSION}`，文档禁止写字面量。升级：改 versions.env → 发版重建镜像。
详见 [工具指南](工具指南.md) §1 / T0 §6。

### Q: 为什么镜像里没有 vite？

A: 刻意不装：vite 产物文件名带内容 hash，`expected.txt` 没法逐行精确比对。
本轨道统一 SFC + SSR 确定输出（编译用 @vue/compiler-sfc，渲染用
@vue/server-renderer）。详见 [工具指南](工具指南.md) §2.4 / [开发指南](开发指南.md) §1。

### Q: `Cannot find module 'vue'` 怎么回事？

A: 多半用了 ESM `import`——镜像的全局模块靠 `NODE_PATH` 解析，只对 CommonJS
`require` 生效。用例统一 `require`；项目里要 ESM 就先本地 `npm install vue`。
详见 [工具指南](工具指南.md) §2.1、§4。

### Q: 宿主机没装 Node，怎么格式化 / 跑测试？

A: 全部走容器：格式化 `bash scripts/fmt.sh --lang vue`（fmt.sh 管 vue 轨道，
容器内执行 prettier）；毕业项目冒烟按 [开发指南](开发指南.md) §4 的
docker run 形式进容器跑。详见 [工具指南](工具指南.md) §2.3。

## 用例与构建

### Q: 怎么跑单个教学用例？

A: 仓库根执行 `TAG=latest scripts/run-example.sh vue <ID>`，例如
`TAG=latest scripts/run-example.sh vue L0-hello`（实测 PASS）；
列清单 `scripts/run-example.sh vue --list`。ID 全表见 [知识点清单](知识点清单.md)。
详见 [开发指南](开发指南.md) §3。

### Q: ref 和 reactive 到底怎么选？

A: 简单值、需要整体替换用 ref；对象/集合且不想到处 .value 用 reactive，
但注意解构丢响应性。可观察判据与练习见 L1-002-ref-vs-reactive。
原理层（Proxy 实现）见 L3-001-proxy-reactivity。详见 [知识点清单](知识点清单.md)。

### Q: runner 说「期望输出不匹配」，怎么对现场？

A: 期望值就是用例目录里的 `expected.txt`（逐行精确、忽略行尾空白）。加 `--keep`
保留容器，`docker exec` 进去手动跑 `run.sh` 逐行 diff。
详见 [开发指南](开发指南.md) §3 / T0 §1。

## 测试与调试

### Q: 毕业项目怎么验证没被改坏？

A: 容器内跑冒烟：`docker run --rm -v "$PWD/vue/project:/work/vue/project" -w /work/vue/project "ghcr.io/zeek-zhao/devbox-vue:${TAG:-latest}" bash test/smoke.sh`
——起 SSR 服务并断言响应含种子 todo（实测输出 `SSR smoke passed ...`）。
详见 [开发指南](开发指南.md) §4 / 用例 L2-004-unit-test-harness。

### Q: 渲染性能怎么量？

A: 毕业项目自带基线脚本：`npm run perf`（node src/perf/baseline.js），
练法与判读见 L3-012-render-perf-baseline。详见 [工具指南](工具指南.md) §2.2。

### Q: 格式化 CI 红了但我本地「已经是格式好的」？

A: 多半绕过了统一入口或裸跑 prettier 没带 ignore。宿主用
`bash scripts/fmt.sh --check --lang vue`（与 CI 同命令、同镜像口径）复查；
规则真本是仓库根 `.prettierrc.json`。练习见 L2-005-prettier-check。
详见 [工具指南](工具指南.md) §2.3。

## 文档与流程

### Q: 文档里能写具体版本号吗？

A: 不能。一律写 `images/versions.env` 的变量名（如 `${NODE_VERSION}`）：写字面量，
升级当天文档集体过期。镜像 tag 同理，命令统一
`TAG=latest scripts/run-example.sh ...`。详见 T0 §6 / [开发指南](开发指南.md) §1。

### Q: 提交被拒：身份不允许 / AI 署名？

A: author 和 committer 都必须在白名单（当前 `zeek.zhao <zeek.zhao@foxmail.com>`），
且提交信息禁止 `Co-authored-by:` / `Generated with` 尾巴。先
`git config user.name zeek.zhao && git config user.email zeek.zhao@foxmail.com`。
详见 T0 §5。

### Q: 想加 eslint / vitest 当门禁，可以吗？

A: 可以自装到项目里用，但把它们加进门禁属于改判定标准，必须走 T0 §3 的
人工评审放行并在 PR 里写明理由；镜像口径（不装 vite 等）同理不许悄悄改。
详见 [工具指南](工具指南.md) §2.4。

## 查不到时去哪查

- **练什么 / 用例 ID**：`vue/docs/知识点清单.md`（L1–L3 各级表格）。
- **工具怎么调 / 是否预装**：[工具指南](工具指南.md)；排查类长问题等 Vue 轨道
  G3 问题指南（M8 建成）承接，先按工具指南 §2 的定位命令走。
- **runner / CI / 门禁 / 提交 / 发版**：`docs/13-通用开发指南.md`（T0 单一真本）。
- **已知坑登记**：`docs/ROADMAP.md` 的 KI 段、`docs/40-问题清单.md`。
- **上游文档**：镜像内 `node -p "require('vue/package.json').version"` 确认同版本后
  查 vue 官方文档（注意与本工程 SSR/require 口径的差异）；再查不到带 `--keep`
  现场去 GitHub issue 搜索 / 提 issue。
