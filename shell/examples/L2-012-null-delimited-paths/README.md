# L2-012-null-delimited-paths


## 考点
对应 KP-SH-L2-12：文件名流用 NUL 分隔，安全传递空格和换行。
两个特殊文件名通过 `find -print0` 与 `xargs -0` 计为两项，说明文件名不会被拆开。

## 易错点
换行分隔会把合法文件名切成多个条目，因为文件名本身可以包含换行符。
使用 NUL 分隔的生产者和消费者，不要把文件名流接到逐行文本管道。

## 延伸
在递归巡检和批处理脚本中用 `find -print0` 配合 `xargs -0` 或 `read -d ''`。
扩展夹具覆盖前导短横线、空格和换行等合法文件名。

## 复现
TAG=latest scripts/run-example.sh shell L2-012-null-delimited-paths
