# L3-007-unsafe-raw-pointer

## 考点
对应 KP-RS-L3-07：裸指针解引用与 from_raw_parts 安全前提。只从有效活体数组构造指针切片并得出和；任一指针、长度或初始化前提失效都可能是 UB

## 易错点
裸指针非空并不代表它可安全解引用：若地址未对齐、内存已释放、长度越界或元素未初始化，`from_raw_parts` 都可能造成未定义行为。调用前必须证明整段内存有效且在返回切片的生命周期内持续存活；能用安全切片 API 时就不应绕到 `unsafe`。

## 延伸
项目的 `src/lib.rs` 生产路径用文件、切片和迭代器等安全 API 处理文本，没有真正需要裸指针的地方；`raw_slice_is_built_only_from_valid_live_storage` 只是边界示例。CLI 不应为普通文本处理增加 `unsafe`，本例只作安全前提辨识练习。

## 复现
TAG=latest scripts/run-example.sh rust L3-007-unsafe-raw-pointer
