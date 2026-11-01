# @zeek/release

基于 [Conventional Commits](https://www.conventionalcommits.org/) 的版本管理工具：
**算版本号 → 写版本文件 → 生成 CHANGELOG → 打 tag → 提交**，一次做完。

从 `standard-version` 的实践里提炼，但补了它没管的那部分：**安全默认**。

## 为什么不用 standard-version

`standard-version` 很好用，但它在别人的仓库里跑的时候，有几件事它不管：

- 工作树脏着也照样 bump，回滚时分不清哪些改动是自己的
- 在 `main` 上直接提交 release commit，绕过分支保护
- 扫到哪个版本号字段就改哪个，`GO_VERSION=1.27.3` 这种依赖版本也会被当项目版本

`@zeek/release` 把这些都做成**默认拒绝**。

## 用法

```bash
# 预览（默认就是预览，不会改任何文件）
npx @zeek/release

# 真的要写
npx @zeek/release --write

# 强制指定版本类型
npx @zeek/release --write --release-as minor

# 在受保护分支上跑（显式授权）
npx @zeek/release --write --allow-branch main

# 固定 CHANGELOG 日期（也可设置 RELEASE_DATE 环境变量）
npx @zeek/release --date 2026-11-01
```

未指定 `--date` 或 `RELEASE_DATE` 时，CHANGELOG 使用最新提交日期，保证重复预览可复现。

## 安全默认（六条，一条都不让步）

| # | 规则 | 为什么 |
|---|---|---|
| 1 | **默认 dry-run**，只有 `--write` 才落盘 | `npx` 敲下去应该是预览，不是已经打完 tag |
| 2 | **工作树脏就拒跑**，不提供 `--force` | 脏树下 bump，回滚时分不清谁改的 |
| 3 | **`main`/`master` 默认拒绝**，要 `--allow-branch` | 别人的分支保护规则各不相同，不能假设 |
| 4 | **版本号只认白名单文件**，永不推断 | 把依赖版本当项目版本 bump 一次就全盘皆错 |
| 5 | **不自动 push** | tag 和 commit 留在本地，推不推由人决定 |
| 6 | **不联网、不调 API** | 工具只碰本地 git 与文件 |

## 目录

```
src/
├── cli.js           # 入口：参数解析 + 六条安全门的落点
├── config.js        # 读 release.config.js，校验并补默认值
├── commits.js       # 从 git log 解析 conventional commits
├── bump.js          # 由 commits 算下一个版本
├── changelog.js     # 渲染 markdown 分节
├── version-file.js  # 按白名单读写版本号（json / plain / toml）
├── git.js           # tag / commit 封装
└── plan.js          # 把上面组合成「将要做的事」列表（dry-run 的输出就是它）
test/
docs/
├── 01-核心概念.md    # Bump / Changelog / Commit / Tag
└── 02-快速上手.md
```

## 开发

```bash
cd shared/release
node --test test/
```
