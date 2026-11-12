# T-001-props-reactivity-env · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：后台管理页「运营位开关」永远是页面初值——后端确认数据推送正常、父组件
v-for 绑定也在动，唯独这个子组件不跟。另一个更隐蔽的现场：昨天改了个「环境变量」，
`vite build` 零告警全绿，上线后接口请求打到 `undefined`，网关日志里 URL 是字面量
`null`。你在 devbox-vue 容器里拿到缩小版现场：

```bash
cd vue/examples/T-001-props-reactivity-env/app
npm install
node src/props-repro.mjs; echo "rc=$?"
npx vite build && grep -o 'void 0' dist/assets/*.js | wc -l
```

`npm run build` 全绿、ESLint/类型检查无告警——但「文本冻在初值」与「产物里躺着
undefined」都是事实，review 时谁也指不出哪一行有问题。

## 你的任务

1. 先排除「脚本没真正跑起来 / 依赖没装上」（devbox-vue 镜像不带 vite，依赖走内嵌
   app/ 工程安装；先趟过去再谈代码）；
2. 判断「文本不更新」时组件到底有没有重渲染、读的是哪份值；用工具把它钉到
   app/src/props-repro.mjs 的具体行，并回答：更新链路坏了吗？改传参方式能修吗？
3. 产物里的 `void 0` 对回 src/main.js 的哪两行？为什么构建日志看不到？给出两类
   缺陷各自的修复 diff 与修复后验证证据（判据必须钉在产物/运行时，不是钉在
   「构建没报错」）。

## 可用工具清单（均在 devbox-vue 镜像内可用）

- node v22 / npm 10（vue@3.5 / vite@5 由内嵌 app/ 工程安装，npm 需可达 registry）
- Vue 公开 API：`createRenderer`（headless 挂载，无 DOM 依赖）、`reactive`/`effect`/
  `nextTick`（@vue/reactivity 原语层隔离实验）
- `vite build` + 产物静态 grep（`grep -o ... | wc -l`）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
