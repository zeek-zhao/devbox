# L1-037-from-conversions

## 考点
对应 KP-RS-L1-37：From、Into、TryFrom 与 ? 的错误转换。字符串可通过 Into 构造拥有值，? 传播解析错误且 TryFrom 拒绝超出 u16 的值

## 易错点
只给错误类型实现 `From` 并不会自动把所有数值转换都变安全，窄化到 `u16` 仍可能失败，必须用 `TryFrom` 检查范围。`?` 只会沿当前返回类型支持的 `From` 路径转换错误；为目标错误类型实现对应转换后，解析错误才能自然传播。

## 延伸
项目的 `src/lib.rs` 为 `AppError` 实现 `From<io::Error>`，因此 `run` 和 `collect_files` 中文件系统操作的 `?` 会统一转换成应用错误。`From` 负责这条可失败 I/O 路径，示例里的 `TryFrom` 则对应需要验证数值范围的转换。

## 复现
TAG=latest scripts/run-example.sh rust L1-037-from-conversions
