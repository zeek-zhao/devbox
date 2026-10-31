# L2-001-script-skeleton-usage


## 考点
对应 KP-SH-L2-01：Bash 入口使用 shebang、严格模式、参数校验和 usage。
合法的 `deploy` 参数进入处理分支；未知选项返回非零并将 usage 写到 stderr，说明入口契约有效。

## 易错点
缺少参数校验会让错误输入沿默认路径执行，调用方可能误以为部署成功。
入口先检查参数数量和选项；失败时输出 usage 到 stderr 并返回非零。

## 延伸
把入口扩展为带必需参数的部署命令，并为每个参数定义缺失和非法值的行为。
将帮助信息与退出状态纳入毕业项目命令行接口的回归测试。

## 复现
TAG=latest scripts/run-example.sh shell L2-001-script-skeleton-usage
