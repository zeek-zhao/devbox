# L2-008-subprocess


## 考点
对应 KP-PY-L2-08：使用 `subprocess.run` 的参数列表、捕获输出并检查返回码。
含空格参数完整到达子进程，非零状态被 `check=True` 转成异常，说明调用边界明确。

## 易错点
拼接 shell 字符串会带来转义和注入风险，也容易产生平台差异。
默认传参数列表并使用 `check=True`；只有明确需要时才启用 shell。

## 延伸
为外部数据工具封装参数列表、超时和返回码处理，避免散落裸进程调用。
分别测试标准输出、错误状态和超时等边界，并避免记录敏感参数。

## 复现
TAG=latest scripts/run-example.sh python L2-008-subprocess
