<!-- coverage: exempt 响应尺寸固定且有界，`snprintf` 已能安全构造。 -->

# L3-010-string-builder —— 按倍数扩容构建字符串

## 考点

- 动态追加片段并始终维护 NUL 结尾。
- 通过容量翻倍避免每次追加都重新分配。
- 对最终内容计算确定性哈希。

## 为什么这么写

追加前一次性确保足够容量，容量从 16 开始翻倍；最终长度和哈希一起验证全部内容。

## 易错点

- 容量检查必须为末尾 `\\0` 预留一个字节。
- `realloc` 失败不能丢失已有字符串的指针。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-010-string-builder
```
