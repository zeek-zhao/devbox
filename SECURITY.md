# 安全策略

## 支持范围

本项目是**教学仓库**：所有代码用于演示语言特性与工程实践，容器镜像仅设计为在
本机运行。仓库不提供任何托管服务，也没有生产部署。

因此「支持版本」只有一条：

| 版本 | 是否接受安全报告 |
|---|---|
| `main` 分支最新提交 | 是 |
| 已打 tag 的版本 | 是（仅针对该 tag 引入的缺陷） |
| 更早的历史提交 | 否，请先确认在 `main` 上可复现 |

## 报告漏洞

**请不要开公开 Issue。** 用下面任一渠道：

1. GitHub 私密报告：<https://github.com/zeek-zhao/devbox/security/advisories/new>
2. 邮件：zeek.zhao@foxmail.com

报告里请包含：受影响的提交或 tag、复现步骤、影响范围、以及你建议的修复方向。
如果涉及镜像内的第三方组件（Ubuntu 包、语言工具链、数据库服务），请注明具体组件
与版本——那类问题通常需要上游修复。

## 响应

- 3 个工作日内确认收到并给出初步判断
- 确认成立后 14 天内给出修复或缓解方案
- 修复发布后，如果你同意，会在 advisory 里署名致谢

## 已知的「不是漏洞」

下面这些是教学仓库的**设计取舍**，不需要报告：

- **示例口令明文**：`db/docker/docker-compose.yml` 与 `db/examples/*/run.sh` 里的
  `password="devbox"` 一类口令是给本地容器用的固定值。这些服务只监听 Docker 内部
  网络，不映射到宿主机以外的接口。**绝对不要把这些配置搬到任何联网环境。**
- **db 的 toolbox 容器仍以 root 运行**：devbox 各层镜像已经改成非 root（默认以
  `dev` 运行，启动时把它的 uid/gid 对齐宿主），但 `db/docker/toolbox` 是独立镜像，
  用例通过 `docker compose exec` 进去跑 SQL 客户端，仍是 root。它只在本地 compose
  网络里工作，不往宿主的 bind mount 写文件。详见
  [ROADMAP](docs/ROADMAP.md) 的 KI-07。
- **镜像体积较大**：教学镜像装了完整工具链，体积预算见 `images/budgets.tsv`，
  超预算是 CI 问题，不是安全问题。
- **镜像标签可变**：`:latest` 会随 `main` 变动，需要可复现请用 `:sha-<commit-sha>` 标签。
