# L2-010-pathlib-io

<!-- coverage: pending -->

## 考点
对应 KP-PY-L2-10：使用 `Path` 组合路径、读写文本并区分缺失文件。
读回结果相同且缺失路径报告 `FileNotFoundError`，说明掌握了该 KP。

## 易错点
拼接路径字符串易受分隔符影响，吞掉 IO 异常会把故障伪装成空数据。
用 `Path` 操作并报告具体错误，避免把缺失文件和空文件混为一谈。

## 延伸
为输入文件定位定义明确的根目录和相对路径策略。
为报表写入补充原子替换与编码约定。

## 复现
TAG=latest scripts/run-example.sh python L2-010-pathlib-io
