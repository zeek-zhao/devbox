# Shell 毕业项目：用例覆盖表

覆盖 `shell/examples/` 全部 54 个目录，含 hello。落点相对 project/，
指向实际操作或其紧邻注释。JSON 巡检和短选项由 BATS 执行；
其余主流程也由 runtime 固定自检执行。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.sh:5 | Bash 严格模式与 IFS 基线 |
| L1-001-shebang-execution | src/main.sh:2 | shebang 明确选择 Bash |
| L1-002-variable-expansion | lib/common.sh:82 | 展开服务名与大写配置键 |
| L1-003-quoting-word-splitting | lib/commands.sh:17 | 引号保护目标路径和参数，支持空格 |
| L1-004-positional-parameters | src/main.sh:14 | 用 "$@" 完整转发参数 |
| L1-005-ifs-field-splitting | lib/commands.sh:164 | 使用制表符 IFS 解析 TSV |
| L1-006-parameter-default | lib/commands.sh:185 | Bash 命令的默认值展开 |
| L1-007-prefix-suffix-removal | lib/commands.sh:63 | 去目录前缀与 .txt 后缀检查布局 |
| L1-008-parameter-replacement | lib/common.sh:80 | 服务名连字符替换为配置键下划线 |
| L1-009-length-uppercase | lib/common.sh:72 | 长度限制；payload 用大写转换生成键 |
| L1-010-conditional-tests | lib/commands.sh:97 | 检查发布目录存在且非符号链接 |
| L1-011-arithmetic-expansion | lib/commands.sh:48 | 用算术展开累计文件数量 |
| L1-012-if-exit-status | lib/commands.sh:85 | 直接按检查函数的退出码判定结果 |
| L1-013-case-patterns | lib/common.sh:104 | case 匹配长选项并验证所属子命令 |
| L1-014-for-list | lib/commands.sh:109 | 数组逐项启动检查 |
| L1-015-while-loop | lib/common.sh:102 | while/shift 手写长选项解析 |
| L1-016-glob-options | lib/commands.sh:56 | 显式启用 nullglob 和 globstar |
| L1-017-indexed-arrays | lib/commands.sh:104 | 检查列表用索引数组保存 |
| L1-018-associative-arrays | lib/commands.sh:159 | 关联数组去重与保存状态 |
| L1-019-array-at-star | lib/commands.sh:107 | 星号连接诊断文本；@ 保留检查参数边界 |
| L1-020-command-substitution-subshell | lib/commands.sh:188 | 命令替换捕获独立子进程的部署输出 |
| L1-021-pipeline-pipefail | lib/commands.sh:175 | 排序管道由 pipefail 保留任一步失败 |
| L1-022-exit-status | lib/commands.sh:131 | 回传全部 wait 汇总的检查退出码 |
| L1-023-functions-local-return | lib/common.sh:78 | 函数局部变量和显式 return |
| L1-024-stdout-stderr | lib/common.sh:47 | 参数错误只写 stderr |
| L1-025-printf-echo | lib/commands.sh:173 | printf 固定列宽生成表格 |
| L1-026-read-lines | lib/commands.sh:161 | read -r 逐行读取并支持末行无换行 |
| L1-027-heredoc-herestring | lib/commands.sh:194 | 引号 heredoc 创建固定 TSV；报告用 here-string 拆列 |
| L1-028-getopts | lib/commands.sh:137 | report 的 -f/-h 短选项与缺值、未知选项处理 |
| L1-029-trap-mktemp | lib/common.sh:30 | EXIT trap 删除 mktemp 创建的精确目录 |
| L1-030-strict-mode | src/main.sh:3 | set -euo pipefail 防止未处理失败 |
| L1-031-export-environment | lib/common.sh:5 | 导出 C locale 给 sort、awk 等子进程 |
| L1-032-redirections | lib/commands.sh:12 | 独立文件描述符 9 打开部署锁 |
| L1-033-command-lists | lib/commands.sh:9 | mkdir 成功且目录存在才继续，否则诊断失败 |
| L1-034-command-argument-safety | lib/commands.sh:34 | mv -- 和引号阻止路径被解释为选项 |
| L1-035-command-discovery | lib/common.sh:53 | command -v 显式验证外部命令 |
| L2-001-script-skeleton-usage | lib/common.sh:58 | 主入口 usage 与命令契约 |
| L2-002-shellcheck-warning-gate | build.sh:8 | ShellCheck warning 门禁，缺工具时使用本地镜像 |
| L2-003-bats-run-assertions | tests/commands.bats:24 | run 捕获 stdout、stderr 并断言完整固定输出 |
| L2-004-bats-fixtures | tests/commands.bats:3 | setup/teardown 隔离临时目录 |
| L2-005-log-stream-separation | lib/commands.sh:37 | 发布诊断写 stderr，机器结果写 stdout |
| L2-006-flock-reentrancy | lib/commands.sh:14 | 持有非阻塞 flock，拒绝并发发布 |
| L2-007-posix-bash-portability | src/main.sh:7 | BASH_SOURCE 与 source 明确依赖 Bash 而非 POSIX sh |
| L2-008-cli-option-validation | lib/common.sh:107 | 长选项缺值、重复、命令所属关系均拒绝 |
| L2-009-temporary-workspace | lib/common.sh:42 | mktemp -d 工作区与统一 trap 生命周期 |
| L2-010-idempotent-steps | lib/commands.sh:20 | 比较内容与完整性，重复部署不重写 |
| L2-011-failure-diagnostics | lib/common.sh:37 | ERR trap 带状态与行号，保留非零退出码 |
| L2-012-null-delimited-paths | lib/commands.sh:45 | find -print0/read -d '' 支持含换行路径 |
| L3-001-background-wait-sort | lib/commands.sh:120 | 全部并行进程 wait 后排序，失败不丢剩余结果 |
| L3-002-streaming-text-processing | lib/commands.sh:201 | awk 流式统计固定 TSV 的 PASS 数 |
| L3-003-jq-json-processing | lib/commands.sh:79 | jq 嵌套字段中筛选启用的 demo 服务 |
| L3-004-sha256-integrity | lib/commands.sh:74 | 验证固定 SHA256SUMS，篡改会失败 |
| L3-005-globstar-recursion | lib/commands.sh:59 | **/*.txt 递归匹配，额外深层文件导致巡检失败 |
| L3-006-signal-cleanup | lib/common.sh:27 | INT/TERM 退出码触发 EXIT 回收进程组和临时目录 |
