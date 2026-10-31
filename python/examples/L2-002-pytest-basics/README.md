# L2-002-pytest-basics


## 考点
对应 KP-PY-L2-02：用 fixture、参数化、异常断言和 `tmp_path` 编写 pytest 用例。
固定的 pytest 命令通过且临时文件测试隔离，说明测试覆盖了正常与失败路径。

## 易错点
共享固定路径会留下污染，只测正常输入又会漏掉边界与异常行为。
使用隔离 fixture、参数表和 `pytest.raises`，让失败路径也成为明确断言。

## 延伸
为清洗函数增加空值、边界值和非法格式的参数化回归测试。
用 `tmp_path` 验证 CLI 文件输出，确保测试不会依赖或改写仓库数据。

## 复现
TAG=latest scripts/run-example.sh python L2-002-pytest-basics
