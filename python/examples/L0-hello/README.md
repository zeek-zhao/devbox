## 考点
用 `python3` 执行脚本，验证 Python 3.12 解释器及标准库 `dataclasses`、类型标注。
输出只检查主次版本，并验证 3-4-5 距离和 `sum(range(...))` 的结果。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh python hello`。

## 易错点
镜像中的 `python3` 需要是 Python 3.12；其他版本会导致版本输出与预期不符。
不要把完整补丁版本写进预期输出，补丁号可能随镜像更新变化。
