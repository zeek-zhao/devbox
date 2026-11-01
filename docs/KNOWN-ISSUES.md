# 已知问题

> 分四类：**需要人做**（自动化解决不了）、**开放**（可以做但还没做）、
> **已知限制**（不改，是取舍）、**已解决**（留编号便于追溯）。
>
> 前三类里能建 Issue 的已建，**状态以 Issue 为准**；已知限制只记录在本文，不建 Issue
> ——建了也只会变成一条永远开着的噪音。
>
> 编号一旦分配就不再复用。已解决的条目移到文末并保留编号，
> 因为别处的文档会引用「KI-05 那次改名」这类说法。

## 需要人做

### KI-01　人工抽检（M2 / M4 遗留） · [#178](https://github.com/zeek-zhao/devbox/issues/178)

自动化能验「用例跑不跑得过」「覆盖表自不自洽」，验不了「这个用例教的东西对不对」。

| 项 | 内容 | 为什么机器做不了 |
|---|---|---|
| C2 | 抽检 C++ 样板用例的教学质量：考点说明是否准确、边界是否覆盖 | 判断「讲得对不对」需要人读 |
| C4 | 抽读 3 个覆盖落点：`go/project`、`java/project`、`python/project` | 覆盖表只验「ID 出现在非文档文件里」，验不了「这个文件真在用这个模式」 |

**怎么算完成**：抽检记录写进对应 Issue 的评论，问题数 ≤ 2/10 视为通过。

### KI-02　L4 设计模式用例的覆盖策略未定案 · [#179](https://github.com/zeek-zhao/devbox/issues/179)

现状：`go` / `python` / `java` 的 L4 用例以 `coverage: exempt <理由>` 挂在明账上，
`--strict` 能过，但没有强制它们接入毕业项目。

两个选项：

- **A（现状）**：L4 视为可复用结构练习，不要求接入项目，逐条写豁免理由
- **B**：要求 L4 也真接入（例如 cpp 项目真用 Strategy / Observer），代价是项目要改

选 B 的收益是覆盖更实；代价是毕业项目会为了「用上模式」而变形，反而失真。
需要人判断。

## 开放

### KI-04　`docs/进度看板.html` 是静态快照 · [#181](https://github.com/zeek-zhao/devbox/issues/181)

用例数与毕业项目数仍由人写，但已不是「靠自觉」：`scripts/check-board-truth.sh`
在 CI 里比对看板与 `examples/`、`project/` 的实况，不一致即红。
层级分布、项目名这类描述性内容无法机器判定，仍需人工核对。

另注：`scripts/build-board.sh` 生成的是**某一次执行的用例结果看板**，
输出到 `docs/progress.html`（生成物，不入库），与本文件不是同一个东西。

## 已知限制（不改，是取舍）

### KI-06　示例口令明文

`db/docker/docker-compose.yml` 与 `db/examples/*/run.sh` 里有 `password: devbox`
一类固定口令。这些服务只监听 Docker 内部网络，不映射到宿主机以外。

**不改的理由**：用例需要确定性输出与零配置上手，改成随机口令会让每条用例都要
先协商凭据，教学价值反而下降。已在 [SECURITY.md](../SECURITY.md) 显式声明。

### KI-07　db 轨道的 toolbox 仍以 root 运行

九层 devbox 镜像（`base` / `tool` / `runtime` / `all` + 八门语言）已经改成非 root：
默认以 `dev` 运行，启动时把它的 uid/gid 对齐 `HOST_UID` / `HOST_GID`；
需要 root 时显式 `-e DEVBOX_AS_ROOT=1`（或 `-e HOST_UID=0`、`--entrypoint bash`）。

`db/docker/toolbox` 没跟上 —— 它是独立镜像（`FROM ubuntu:24.04`），
用例通过 `docker compose exec` 进去跑 SQL 客户端，仍然是 root。

**暂时不改的理由**：toolbox 只在本地 compose 网络里跑客户端，不往宿主的 bind mount
写文件，也不往仓库里写。改它要连带调整 `docker compose exec` 的用户语义，
而 77 条 db 用例都依赖那条路径 —— 收益小、风险大。

### KI-08　镜像标签可变

`:latest` 随 `main` 变动。需要可复现请用 `:sha-<commit-sha>` 标签——CI 每次构建都会打。

PR 只推 sha 标签、不发 `:latest`（同仓并发 PR 曾互相覆盖被测镜像），
所以 `:latest` 只会被非 PR 事件的构建推进。

### KI-09　历史重写后的旧对象残留

2026-11-01 做过一次全量历史重写（作者归一 + 清除内网地址）。重写后旧提交已从所有
ref 上摘除，但 GitHub 的对象回收是异步的，**知道完整 40 位 SHA 的人**仍可能通过
API 取到旧提交，直到服务端 GC 跑过。

- 影响面：仅限旧提交元数据（一个 RFC1918 私有地址、两个非规范作者邮箱）
- 不会进入搜索索引，也没有 ref 指向它们
- 想立刻彻底清除：删除仓库后重建，或联系 GitHub Support 触发 GC

详见 [开源合规审计](开源合规审计.md) 的「残留风险」一节。

## 已解决

保留编号是为了别处文档里的引用还能对上。详情看对应 Issue 或 `git log`。

| 编号 | 原来是什么 | 怎么解决的 | Issue |
|---|---|---|---|
| **KI-03** | Rust 51 例、Vue 46 例，比其他轨道 74–78 少 | Rust 补到 74（L1 45 / L2 17 / L3 11，**零豁免**，全部真接入）；Vue 补到 74（L1 28 / L2 22 / L3 23，能接的接、接不上的写具体理由） | [#180](https://github.com/zeek-zhao/devbox/issues/180) |
| **KI-05** | `hello` 不在 `L<层级>-<序号>-<slug>` 命名体系内 | 改名为 `L0-hello`，并把 `L0` 定义为「通路验证层」——L1–L4 是知识点难度，L0 是环境自检，语义上本来就该分开 | [#182](https://github.com/zeek-zhao/devbox/issues/182) |
