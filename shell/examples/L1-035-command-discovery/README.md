# L1-035-command-discovery

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-35：用 `command -v` 查询可执行命令，并依据返回状态检查依赖。
`bash` 可发现、不可用依赖被识别为缺失，说明理解命令查找与状态判断。

## 易错点
仅凭命令名假设工具已安装会让脚本在运行中途失败；入口处检查并报告缺失依赖。
在执行依赖命令前用 `command -v` 验证它可从当前 `PATH` 找到，并明确报告缺失。

## 延伸
为入口脚本集中列出必需工具，并在开始有副作用的操作前完成全部检查。
区分 shell 内建命令、函数与 `PATH` 中的可执行文件，按实际依赖类型验证。

## 复现
TAG=latest scripts/run-example.sh shell L1-035-command-discovery
