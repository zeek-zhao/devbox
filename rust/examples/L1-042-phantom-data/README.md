# L1-042-phantom-data

## 考点
对应 KP-RS-L1-42：PhantomData 的类型标记与零大小。标记影响 Id 的类型而不占空间，Id 的存储大小仍只有 u64

## 易错点
以为 `PhantomData<T>` 会替结构体保存一个 `T`，会错误估算大小并误判字段的所有权关系。它是零大小的类型标记，能让编译器在类型检查中考虑 `T`，但不会创建实际值或增加存储空间。

## 延伸
项目的 `src/lib.rs` 暴露 `DocumentCount` 等普通数据类型，没有用 `PhantomData` 标记泛型 ID 或借用关系。CLI 当前没有真正需要零大小类型标记的地方，本例只作类型建模能力练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-042-phantom-data
