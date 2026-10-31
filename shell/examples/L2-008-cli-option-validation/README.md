# L2-008-cli-option-validation


## 考点
对应 KP-SH-L2-08：用 `getopts` 实现可验证的命令行选项契约。
合法参数显示解析结果；未知选项和缺失值均以非零退出并打印 usage，说明错误调用不会被默许。

## 易错点
仅处理已识别选项会默许错误调用；`getopts` 默认错误行为也可能不符合脚本契约。
使用带冒号的选项串，在错误分支设置失败状态并输出用法。

## 延伸
为部署命令明确必选参数、互斥选项及其退出状态，并分别测试合法和非法调用。
将 usage 内容作为稳定接口，便于自动化脚本和用户诊断。

## 复现
TAG=latest scripts/run-example.sh shell L2-008-cli-option-validation
