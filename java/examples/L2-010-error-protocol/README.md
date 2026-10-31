# L2-010-error-protocol


## 考点
对应 KP-JV-L2-10：在程序边界区分用户错误、IO 错误与内部缺陷。
正常、非法参数、缺失文档分别得到 0/2/3；内部缺陷非零退出且保留 cause 类别，说明错误协议明确。

## 易错点
把异常兜底为空列表会让自动化误判成功，因为进程可能仍以 0 退出。
保留 cause 并按类别报告；预期错误映射非零退出，未预期缺陷不能伪装成空结果。

## 延伸
为领域异常增加稳定错误码，并验证 CLI 的 stderr 文案与退出码契约。
让索引读取错误携带相对文档名，同时保留原始 IOException。

## 复现
TAG=latest scripts/run-example.sh java L2-010-error-protocol
