---
title: WALKTHROUGH · T-001-external-dependency（外部依赖故障的工程排障）
track: shared
lab: T-001-external-dependency
难度: P2          # P0–P5 刻度：跨 curl / HTTP 重定向语义 / 取证链三步与归因对照的多步交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-07
素材: 类型①（docs/73 §9「已踩过的坑」，CI run 42009114733）+ 类型②实验（复现命令见 §1）
verified_env: Ubuntu 22.04 宿主（bash 5.1.16 / python3 3.10.12 / curl 7.81.0），无容器依赖，不出网
---

# WALKTHROUGH · T-001-external-dependency

> 依据 [docs/72 排障演练规范](../../../docs/72-排障演练规范.md) §4 编写；所有输出均为
> 2026-11-07 在 Ubuntu 22.04 宿主上真跑所得（端口已归一化为 `<port>`，无内网信息、无真实凭证）。
> 本 lab 不真断网、不访问任何真实网络：`repro.sh` 在 127.0.0.1 起一个受控 HTTP 服务，
> 按「GitHub API → 302 → Azure blob」的真实拓扑模拟外部依赖，401/503 对照即是
> 健康/异常输出对照。**场景原型是仓库真实踩过的坑**（docs/73 §9）：CI run 42009114733
> 的「用例-db」job 全红，真实根因是外部镜像源 TLS handshake timeout，而排障者取日志时
> 又被「第二次请求带了 Authorization → Azure blob 返 401」二连坑。

## 1. 触发症状

最小复现（`bash repro.sh`；故障被触发 = 非零退出码，docs/72 §2）：

```text
repro: 对照（不带 Authorization）→ HTTP 200（健康时 200）
repro: 故障（带 Authorization）→ HTTP 401（Azure blob 拒收凭证）
repro:   <Code>AuthenticationFailed</Code>
repro: 故障已复现（外部依赖拒收凭证 → 401），按 docs/72 §2 以非零退出码表示
```

演练全程（`bash run.sh`）的真实输出骨架见 §4；日志侧的症状是三类同框：

- **取证被坑**：拿 job 日志时收到 `401 AuthenticationFailed`——像是令牌坏了；
- **依赖真坏**：日志里 `##[error] Timeout: TLS handshake timeout (registry mirror)`；
- **症状跑偏**：`##[error] service "toolbox" is not running` + 77 个用例 76 个失败，
  看起来像「整轨用例代码全坏了」。

来源：类型①（docs/73 §9 登记的真实坑，含 CI run 42009114733 与同 job 41938551949
success 的对照）+ 类型②实验（本目录 repro.sh / run.sh，2026-11-07）。

## 2. 前 60 秒三条只读检查（成本从低到高）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:<port>/health` | `200`（服务活着，现场可复现） | 连接拒绝 / 非 200：模拟环境本身没起来，先修环境再谈归因（S-06 纪律） |
| 2 | `curl -s -H "Authorization: $TOKEN" "$root/actions/runs/<run_id>/jobs"` | `200` + JSON 里的 `job id` 与 `conclusion` | `401 Requires authentication`：API 层鉴权就没过，**别跳到下游**，先查令牌/头拼写 |
| 3 | `curl -s -D - -o /dev/null -H "Authorization: $TOKEN" "$root/actions/jobs/<job_id>/logs"` | `302` + `Location:` 头（日志正文在别处） | `200` 直出正文（拓扑变了，无 302 可跟）或 404：job id 抄错，回检查 2 |

三条都是只读命令，任何环境都该成功；第 1 条的 `<port>` 来自 `repro.sh start`
输出的 `MOCK-READY port=<N>`。

## 3. 互斥决策树

每个分叉二选一，无死分支、无循环：

```text
第二次请求（302 Location 指向的日志下载）返回什么？
├─ 200
│   └─ grep -nE 'error|timeout|service .* is not running' <日志>
│       ├─ 有命中 → 按命中内容归因：TLS handshake timeout / 镜像源类 → 依赖侧故障，
│       │            留证（时间点 + 日志行）+ 等恢复/重试，不动用例代码
│       └─ 无命中 → job conclusion 与日志内容对不上 → 停，交维护者
│                   （S-07：别拿单点结论当真因）
├─ 401 → 你把 Authorization 头带到了 blob → 去掉头重试（本坑，§4 判读 2）
│         └─ 去头后仍 401 → 才轮到「凭证/权限」假设，回检查 2 对照 API 层表现
├─ 503 / 5xx → 外部依赖本体不可用（与凭证无关）→ 留证 + 等恢复，脚本不用改，
│               代码更不用改；连续两轮同型失败按环境故障升级（docs/73 §9 纪律）
└─ 403 / 404 → Location 过期或签名/路径问题 → 重新走检查 3 拿新 Location
              └─ 新 Location 仍失败 → 停，交维护者（拓扑与本文档描述不符）
```

## 4. 逐行判读（run.sh 七步全绿实录，2026-11-07）

```text
=== [step 1] 受控模拟服务就绪：/health 健康对照（前 60 秒只读检查①） ===
  | MOCK-READY port=<port>
  -> 符合预期
```
第 1 行说明模拟环境起来了且只绑回环（不出网）；端口每次运行不同，**禁止逐字比对**。

```text
=== [step 2] 取证链①：GET /actions/runs/<run_id>/jobs 找失败 job（带令牌 → 200） ===
  | chain①: GET /actions/runs/<id>/jobs → HTTP 200, job id=<job_id>
```
run id → job 清单。200 + 解析出 job id 说明：**API 层令牌是好的**——这行是后面
「401 不是令牌问题」结论的对照证据，没有它，401 会被误读成凭证过期。

```text
=== [step 3] 取证链②：GET /actions/jobs/<job_id>/logs → 302，Location 指向 blob ===
  | chain②: GET /actions/jobs/<id>/logs → HTTP 302
  | chain②: Location=http://127.0.0.1:<port>/blob/logs?sig=SIMULATED&se=...
```
日志正文不在 API 域名下：jobs logs 接口只回 302，真正的日志在 blob 上。**取证链
到这一步分了两个信任域**——这是理解 step 4 的前提。

```text
=== [step 4] 取证链③（真实踩过的坑）：第二次请求把 Authorization 也带上 → 401 ===
  | chain③(坑): 带 Authorization → HTTP 401
  | blob: <Code>AuthenticationFailed</Code>
```
同一个令牌：chain① 是 200，到这里变 401——变的不是凭证，是**收件方**。blob 不认
API 的令牌，带了反而 401。这就是 docs/73 §9 写成纪律的那句「第二次请求不要带
Authorization 头」的完整判读。

```text
=== [step 5] 取证链③修复：第二次请求不带 Authorization → 200 拿到日志 ===
  | chain③(修): 不带 Authorization → HTTP 200
```
改动后验证的第一半：去掉头，立刻 200。修复是**一行**的（删掉第二次请求的
`-H "Authorization: ..."`），且可以当场验证——不需要等任何人。

```text
=== [step 6] grep 取证：从日志里捞真因 ===
  | 2:... ##[error] Timeout: TLS handshake timeout (registry mirror)
  | 3:... ##[error] service "toolbox" is not running
  | 4:... ##[error] 77 个用例 76 个失败
```
因果链自上而下：TLS handshake timeout（因，外部镜像源）→ 镜像拉不下来 →
service not running → 用例全红（果）。**根因在依赖侧，不在用例代码**——按
docs/73 §9：环境故障只取证，不动用例，更不让 AI 去「修」。

```text
=== [step 7] 归因对照：把依赖打挂（mode=down）→ 同样请求变 503 ===
  | down: 同样不带 Authorization → HTTP 503（503 = 依赖本体不可用）
  | 恢复: mode=up 后 → HTTP 200（200 = 是否带凭证与可用性互不相干）
```
归因对照实验：请求方式不动，只把依赖打挂，401 变 503——证明 401 与 503 是
**两种不同因的故障**（收件方拒凭证 / 依赖本体不可用），互斥、修法不同。

### 4.1 POE 点（predict–observe–explain，先写预测再看输出）

- **预测**：跑 step 4 前，书面回答「chain① 用这个令牌是 200，那 chain③ 跟随 302
  下载日志，带着同一个令牌应该返回什么？」多数人会写 200（「带令牌总比不带安全」）。
- **观察**：`bash run.sh` step 4 实际输出 `HTTP 401 + AuthenticationFailed`。
- **解释**：302 之后信任域换了（API → blob），令牌的效力不跨域；「全局统一带鉴权头」
  这个图省事的脚本写法，恰恰是坑的来源。落差即本 lab 的核心知识点。

### 4.2 被否决的假设（专家的排除过程）

1. **假设「job 全红 → 用例代码坏了」**：若真，同一 job 历史轮次应同样红。实际
   docs/73 §9 记录同 job 在 run 41938551949 是 success，且红的那轮日志第一因是
   `TLS handshake timeout`——先于任何用例代码执行。看到「依赖侧报错在用例报错之前」
   就该信依赖假设 → 排除用例假设。
2. **假设「blob 401 → 令牌过期/权限不够」**：若真，检查 2 的 jobs API 也该 401。
   实际 chain① 200、chain③ 401，唯一差异变量是收件方。看到「同一个令牌一部分 200
   一部分 401」就该信信任域假设 → 排除凭证假设。
3. **假设「401 和 503 是同一种外部依赖故障」**：若真，把依赖打挂（mode=down）后
   不带凭证的请求应保持原状。实际变成 503、恢复后 200，且 401 只由带凭证触发——
   两种故障因不同、修法不同（改脚本 / 等恢复）→ 排除同因假设。

## 5. 改动后验证

修复动作：第二次请求**去掉** `-H "Authorization: ..."`（对照 `repro.sh` 内
「对照/故障」两行命令的差集）。验证三件套：

1. `bash repro.sh`：对照行 200 / 故障行 401，复现仍稳定（回归可测）；
2. `bash run.sh`：RUN-PASS：7/7，退出 0；连跑两次结论一致（2026-11-07 实测 3 次全绿）；
3. `grep -nE 'error|timeout|service .* is not running' <日志>`：命中 ≥3 行，
   证明拿到的是**真实日志**而不是 401 的错误页（健康对照：401 页里 grep 不到
   `##[error]`）。

## 6. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `python3` / `curl` 任一 `command not found`（环境缺工具，先修环境）；
2. `repro.sh start` 连续两次起不来（端口被占 / 防火墙拦回环，属环境问题）；
3. 同一验证命令连续两次失败（含 run.sh 连红两次）；
4. 需要修改本 lab 目录之外的文件才能继续；
5. **真实环境取证**时遇到内网地址、真实令牌：先脱敏再留痕，禁止原样粘贴进任何文档。

## 7. last verified 与 UNVERIFIED 表

**last verified: 2026-11-07**，Ubuntu 22.04 宿主（bash 5.1.16 / python3 3.10.12 /
curl 7.81.0，Linux 6.8）。`run.sh` 连跑 3 次均 RUN-PASS 7/7、退出 0；`repro.sh`
连跑 2 次均稳定复现 401、退出 1（故障已触发的约定语义，docs/72 §2）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| 真实 GitHub API + 真实 Azure blob 的 302/401 行为 | UNVERIFIED | 本 lab 全部在受控模拟上验证；真实链路的证据以 docs/73 §9 登记的 CI run 为准 | 下次真实环境取证时按 §2 检查 3 复核并回填 |
| devbox 各语言镜像内 python3/curl 是否齐备 | UNVERIFIED | 本 lab 设计为 runner 原生可跑，未逐镜像核对 | 接入 labs CI 时按实际镜像复跑 |
| CI labs job 对 `shared/examples/` 的处理 | VERIFIED（`#390`） | `ci.yml` labs job 按 `*/examples/T-*/run.sh` 扫描；`images/lang-images.tsv` 无 `shared` 条目时走「无镜像层映射，runner 直跑」分支（#276 已落地），本卡宿主抽验通过 | 若 shared 后续新增镜像层，需同步 `images/lang-images.tsv` |
| curl 未来版本对「跨域重定向自动剥 Authorization 头」行为的变化 | UNVERIFIED | 本 lab 取证链是显式两步请求，不依赖重定向自动跟头语义 | 升级 runner/镜像时复跑 step 4 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 8. 素材来源

- **类型①**（仓库已登记的已知问题）：[docs/73 §9](../../../docs/73-M11并发执行计划.md)
  「已踩过的坑」——CI run 42009114733（纯文档提交却「用例-db」全红），真实根因
  `docker.m.daocloud.io` TLS handshake timeout，同 job run 41938551949 success；
  取证链三步与「第二次请求不带 Authorization」纪律即出自该节。
- **类型②实验**：§1/§4 全部现象均为 2026-11-07 真跑所得，复现命令即 `repro.sh`
  与 `run.sh`；输出已归一化（端口 → `<port>`），不含内网信息与真实凭证。
- [docs/72 排障演练规范](../../../docs/72-排障演练规范.md)：目录契约、断言方式
  （关键诊断行 + 退出码，禁逐字比对）、WALKTHROUGH 结构与素材纪律。
