# L3-005-globstar-recursion


## 考点
对应 KP-SH-L3-05：启用 `globstar` 后用 `**` 遍历多层目录并稳定输出匹配项。
深两层的 `one/two/deep.txt` 被找到、空匹配有明确分支且结果排序，就说明掌握了该 KP。

## 易错点
未启用 `globstar` 时 `**` 不会递归到深层；未启用 `nullglob` 时空匹配会保留字面模式。
显式启用两个选项，并约定默认不匹配隐藏文件；需要隐藏项时应另行明确遍历策略。

## 延伸
为递归巡检增加文件类型筛选，并比较 Bash glob 与 NUL 安全的 `find` 遍历。
处理含空格文件名时继续使用数组，避免通过未加引号的文本拆分路径。

## 复现
TAG=latest scripts/run-example.sh shell L3-005-globstar-recursion
