# L1-032-json-tags

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-32，观察结构体标签将导出字段编码为固定键名，并让空 note 字段省略。
固定 JSON 文本可解码回字段值，未导出的字段保持空值，即可验证编解码契约已掌握。

## 易错点
未导出字段不会被 encoding/json 编码；不要依赖 map 键顺序等实现细节作为语义。
使用导出字段与显式标签，并只断言本例展示的格式契约。

## 延伸
为配置结构增加校验步骤，并在解码后拒绝缺失或越界的字段值。
比较 omitempty 对零值字段的影响，再为稳定外部格式编写兼容性测试。

## 复现
TAG=latest scripts/run-example.sh go L1-032-json-tags
