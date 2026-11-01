# L1-039-asref-borrow

## 考点
对应 KP-RS-L1-39：AsRef 与 Borrow 泛型边界。同一 AsRef 函数接收字面量和 String，Borrow 允许以 &str 查询 String 键

## 易错点
把 `AsRef` 和 `Borrow` 当成可互换的“转成引用”接口，会忽略 `Borrow` 对等价键的哈希和相等语义要求。泛型文本输入只需统一借用视图时用 `AsRef`；要用 `&str` 查询以 `String` 为键的哈希表时，键类型还必须实现匹配的 `Borrow<str>`。

## 延伸
项目的 `src/lib.rs` 在 `parse_args` 中借用 `&[String]` 并显式取出 `&str`，没有通用 `AsRef` 输入函数或 `Borrow` 哈希键查询。当前项目没有真正依赖这两个泛型边界的地方，本例只作借用接口能力练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-039-asref-borrow
