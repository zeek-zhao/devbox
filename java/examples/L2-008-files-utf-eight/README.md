# L2-008-files-utf-eight


## 考点
对应 KP-JV-L2-08：用 Files/Path 与 UTF-8 读写文件。
中文往返一致、空文件长度为 0、缺失文件抛出明确异常且删除后不存在，说明掌握了显式编码与错误区分。

## 易错点
隐式字符集会让中文乱码；吞掉 IOException 会把缺失文件伪装成空输入。
读写都显式指定 UTF-8，并区分 NoSuchFileException；临时目录在 finally 中清理。

## 延伸
将固定路径读写扩展为文档读取服务，并测试权限错误、截断输入等 IO 失败。
比较 Files.readString 与流式读取大文件时的内存取舍。

## 复现
TAG=latest scripts/run-example.sh java L2-008-files-utf-eight
