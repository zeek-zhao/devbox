# shared/ —— 跨语言复用的 shell 工具

各语言用例里反复要写的东西：彩色日志、读写 JSON/YAML、跑 bats、批量修 git author。
把它们收在这里，用例和脚本直接 `source`，不要再各写一份。

```
shared/
├── lib/
│   ├── log.sh    彩色日志 + die + log_run
│   ├── json.sh   jq 封装（依赖 jq）
│   └── yaml.sh   yq 封装（依赖 mikefarah/yq v4）
├── tests/
│   ├── run.sh        测试入口（缺依赖自动进 devbox-shell 镜像）
│   ├── test_log.bats
│   ├── test_json.bats
│   └── test_yaml.bats
└── bin/
    └── repo-fix-git-authors.sh   批量统一历史 author
```

## 怎么用

```bash
# 在用例的 run.sh 里，从仓库根算相对路径
source "$(dirname "$0")/../../../shared/lib/log.sh"

log_info "开始编译"
log_run gcc -std=c17 -O2 -Wall -Wextra -Werror -o app main.c
log_debug "只有 LOG_DEBUG 非空时才打印"
```

```bash
# JSON / YAML
source shared/lib/json.sh
json_create out/conf.json '{"name":"demo","items":[]}'
json_array_add out/conf.json '.items' '"a"'
json_read out/conf.json '.items | length'      # → 1

source shared/lib/yaml.sh
yaml_create out/conf.yaml 'app:
  debug: true'
yaml_update out/conf.yaml '.app.debug' 'false'
```

```bash
# 跑测试（宿主有 bats+jq+yq 就直接跑，否则自动进 shell 镜像）
bash shared/tests/run.sh
bash shared/tests/run.sh --filter json
make test-shared
```

## 约定（踩过坑才写下来的）

- **所有日志走 stderr**，stdout 只留数据。否则 `x=$(json_read ...)` 会拿到一坨时间戳。
- **不定义名为 `run` 的函数**。bats 内置 `run`，一旦被覆盖，所有
  `run xxx; [ "$status" -eq 0 ]` 断言都会静默失真（历史 bug：json 0/13、yaml 0/25 全挂，
  根因就是 `log.sh` 里有个 `run`）。要执行命令用 `log_run`。
- **`log_debug` 在 `LOG_DEBUG` 未设置时返回 0**。原来返回 1，
  在 `set -e` 和 bats（内部 `set -eET`）下会把「没有 debug 日志」判成失败。
- **`NO_COLOR=1` 关颜色**，在 **source 之前**设置才生效（颜色是 source 时求值的，
  和 `chalk` 之类的库一个套路）。日志进文件或 CI 时更干净，断言也不用剥 ANSI。
- **库不改变调用方的 shell 选项**。不要在库里写 `set -e` / `set -o pipefail` / `IFS=...`。
- **库不覆盖通用变量名**。内部临时变量带前缀（`_json_sh_dir`）并在用完后 `unset`，
  不要占用 `LIB_DIR` / `CURRENT_DIR` 这种名字。
- **`check_*` 返回 1 而不是 `exit 1`**。库 `exit` 会把 source 它的调用方直接干掉。
- **写文件先落临时文件再 `mv`**。校验失败时不留半成品，`[ ! -f x ]` 这种断言才立得住。
- **yq 只认 v4**。v3 的 `yq read/write` 和 v4 的 `yq eval` 完全不同，混用会静默写坏文件，
  所以 `check_yq` 会挡 v3。
- **可重复 source**。`log.sh` 第二次 source 直接 `return 0`。

## 函数索引

> 这张表由 `scripts/check-shared-index.sh` 校验：`shared/lib/*.sh` 里每个函数
> 都必须在这里出现，漏了就 CI 红。加函数请顺手加一行。

### lib/log.sh

| 函数 | 说明 |
| --- | --- |
| `log_info <msg...>` | 蓝色 INFO，走 stderr |
| `log_success <msg...>` | 绿色 SUCCESS |
| `log_warn <msg...>` | 黄色 WARN |
| `log_error <msg...>` | 红色 ERROR |
| `log_debug <msg...>` | 紫色 DEBUG，仅 `LOG_DEBUG` 非空时输出；否则返回 0 |
| `log_section <msg...>` | 带 `====` 分隔线的段落标题 |
| `die <msg...>` | 打 ERROR 后 `exit 1` |
| `log_run <cmd...>` | 先打 `+ cmd` 再执行，透传退出码（替代被禁用的 `run`） |

### lib/json.sh（依赖 jq）

| 函数 | 说明 |
| --- | --- |
| `check_jq` | 缺 jq 返回 1 |
| `json_create <file> <json>` | 写文件并校验格式，失败不留文件 |
| `json_read <file> [查询]` | 读，默认整份；查不到返回 1 |
| `json_update <file> <路径> <值>` | 改或加字段，值要自带 JSON 引号 |
| `json_delete <file> <路径>` | 删字段或数组元素 |
| `json_array_add <file> <数组路径> <元素>` | 往数组尾部追加 |

### lib/yaml.sh（依赖 yq v4）

| 函数 | 说明 |
| --- | --- |
| `check_yq` | 缺 yq 或版本 < v4 返回 1 |
| `yaml_create <file> <yaml>` | 写文件并校验格式 |
| `yaml_read <file> [查询]` | 读，默认整份 |
| `yaml_update <file> <路径> <值>` | 原地改或加字段 |
| `yaml_delete <file> <路径>` | 原地删字段 |
| `yaml_array_add <file> <数组路径> <元素>` | 原地追加数组元素 |
| `yaml_merge <目标> <源>` | 深合并，源覆盖目标 |
| `yaml_to_json <yaml> [json]` | 不传输出文件则打到 stdout |
| `json_to_yaml <json> [yaml]` | 同上 |

### bin/repo-fix-git-authors.sh

批量把一组仓库的历史 author/committer 改成同一个身份，走 `git filter-repo`。

```bash
bash shared/bin/repo-fix-git-authors.sh --repo-root ~/repo \
  --name "Zeek Zhao" --email zeek.zhao@foxmail.com --dry-run
```

| 参数 | 说明 |
| --- | --- |
| `--repo-root DIR` | 扫描目录，递归找 `.git`（默认当前目录） |
| `--name` / `--email` | 目标身份，必填 |
| `--keep PATTERN` | 跳过邮箱含此模式的提交，可重复，默认 `github-actions` |
| `--dry-run` | 只报告，不重写不推送 |
| `--yes` | 不交互确认 |
| `--no-push` | 重写但不推远端 |
| `--log-dir DIR` | 日志根目录，默认 `$TMPDIR/repo-fix-git-authors` |

安全措施：filter-repo 会删 remote，所以先存后恢复；重写前后各存一份
「日期+标题」快照做比对（只有 hash 允许变），不一致就不推；默认逐仓库确认。
日志默认写临时目录 —— 这个工具会在别人的仓库里跑，不该往人家工作树里丢文件。

## 测试覆盖

`shared/tests/` 是这三个库的自测，不是语言用例。跑法见上。
`test_log.bats` 里有一条「不覆盖 bats 的 run 函数」的回归守卫——
它专门盯住上面那个历史 bug，别再删。
