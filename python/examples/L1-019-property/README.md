# L1-019-property


## 考点
对应 KP-PY-L1-19：通过 `property` 将校验后的状态作为普通属性读写。
合法输入经规范化后由 getter 返回，空值在 setter 中抛出 `ValueError`，即说明掌握。

## 易错点
直接公开字段允许调用方绕过校验，造成对象状态不满足不变量。
用 property 暴露读写接口，并把类型与非空检查集中放在 setter。

## 延伸
为报表模型的字段增加规范化逻辑，并为每个不变量编写合法与非法输入示例。
在 setter 中将格式检查与存储形式分开，保持读取接口稳定。

## 复现
TAG=latest scripts/run-example.sh python L1-019-property
