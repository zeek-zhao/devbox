

# L1-001 —— 基本类型宽度与 sizeof

在 C17 中使用 `sizeof` 和 `CHAR_BIT` 观察基本类型及对象指针大小。期望值对应当前
Linux LP64 工具链；特别是 `long` 为 8 字节，不应照搬 Windows LLP64 的结果。
