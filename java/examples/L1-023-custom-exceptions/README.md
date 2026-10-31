# L1-023-custom-exceptions

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-23：用领域异常补充业务上下文，同时保留原始 cause。
看到调用方捕获领域类型、消息含文档名且 cause 仍是 IOException，即说明掌握。

## 易错点
包装时只复制消息会丢失故障根因，排查时无法追到原始异常。
用带 cause 的构造器传递原异常，并在新消息中补充稳定的业务上下文。

## 延伸
为索引加载、解析等边界定义领域异常，并让上层按异常类型决定恢复策略。
为异常消息选择稳定的资源标识，避免暴露机器上的绝对路径。

## 复现
TAG=latest scripts/run-example.sh java L1-023-custom-exceptions
