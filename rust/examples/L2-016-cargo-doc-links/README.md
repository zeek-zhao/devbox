# L2-016-cargo-doc-links

## 考点
对应 KP-RS-L2-16：文档注释 intra-doc link 与 cargo doc。cargo doc 在禁止坏链接的条件下解析 DocumentCount 链接并生成文档

## 易错点
文档链接写成普通文本或拼错公开类型名，页面看起来仍正常，但读者点不到目标，`cargo doc` 也无法替你证明链接有效。使用 intra-doc link 指向实际可见的项，并在启用坏链接告警的文档构建中检查目标是否存在。

## 延伸
项目的 `src/lib.rs` 文档通过 intra-doc link 引用公开类型 `DocumentCount`，`intra_doc_link_target_is_a_public_api_type` 和 rustdoc 构建共同验证目标。链接让 CLI 库的文档读者能直接跳到计数类型说明，类型改名时也能尽早发现失效引用。

## 复现
TAG=latest scripts/run-example.sh rust L2-016-cargo-doc-links
