# T-001-external-dependency · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事在排一次 CI 红叉：job「用例-db」failure，他想拿 job 日志贴到 issue 里取证，
于是照着抓 API 的老脚本改了改——脚本对**每个请求**都统一带 `-H "Authorization: token ..."`
（图省事，把鉴权头写成全局变量）。结果他看到的是：

```text
HTTP 401
<?xml ...?><Error><Code>AuthenticationFailed</Code>
<Message>Server failed to authenticate the request.</Message></Error>
```

同事的结论：「令牌过期了，我先去换个 token；换完还不行就给 db 用例加超时重试，
毕竟 job 也确实是红的。」他已经开了个 PR 准备改用例代码。

## 你的任务

1. 先回答：同一个令牌，请求 `GET /actions/jobs/<id>/logs`（API 域名）返回什么？
   跟随它的 302 去下载日志又返回什么？两者差在哪一个变量？
2. 判定同事的两个结论（令牌过期 / 改用例）各错在哪，用「对照实验」说话，
   不许只靠猜：怎么用一次受控请求证明 401 与令牌本身无关？
3. 401 和 503 是「同一种外部依赖故障」吗？给出一个能把两者**互斥地**分开的判定规则，
   并说明各自下一步动作（修脚本 / 留证等恢复 / 改代码——哪条路都不该走？）。
4. 完整跑一遍本 lab 的 `run.sh`，对照你手写的决策树。

## 可用工具清单

- bash + curl + python3（GitHub 托管 ubuntu runner 预装；本 lab 不需要容器镜像）；
- `repro.sh`：受控模拟服务（只绑 127.0.0.1，不访问任何真实网络），
  `bash repro.sh start` 起服务，`bash repro.sh stop` 停；
- 模拟服务端点：`/health`、`/actions/runs/<id>/jobs`、`/actions/jobs/<id>/logs`、
  `/blob/...`、`/__control?mode=up|down`（语义自己探测，不给答案）。

## 禁止

- 把 Authorization 头带到 302 Location 指向的第二次请求（就是它引发的现场）；
- 访问任何真实 GitHub / Azure 端点——本 lab 的全部取证只在回环地址上完成。
