# L2-003-typing-protocols

<!-- coverage: pending -->

## 考点
对应 KP-PY-L2-03：用 `Protocol` 描述结构接口，以泛型和 `Optional` 表达类型关系。
未继承协议的类通过静态检查并可传入泛型函数，说明理解结构化类型。

## 易错点
类型注解不会在运行时校验输入，错误的外部数据仍可能进入业务逻辑。
由静态检查器验证类型关系；外部数据仍须显式解析并校验。

## 延伸
为可替换的数据源定义协议，再让列表、文件或内存实现提供同一读取方法。
把泛型转换函数用于不同记录类型，并为边界输入补充解析校验。

## 复现
TAG=latest scripts/run-example.sh python L2-003-typing-protocols
