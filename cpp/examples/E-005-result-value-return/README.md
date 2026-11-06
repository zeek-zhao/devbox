# E-005-result-value-return

## 现象
用 `variant<T, E>` 搭一个最小 `Result`：错误是返回类型里的一个值，
`ok()` 检查后才能取值或取错误；`std::optional` 承担「只论有无」的变体。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-005-result-value-return
```

## 期望输出
```text
good: value=entry-42
miss: error=not found
denied: ok=false
denied: error=permissions denied
optional: has=false
optional: value_or=7
```

## 为什么
异常把错误流藏在控制流之外，看函数签名不知道它会失败；Result/expected
把失败写进返回类型——调用方拿到的是一个必须分派的值，不检查就取不出
成功值（variant 强制先看槽位）。适合「未命中/拒绝输入」这类预期内的失败：
调用点就地分派、错误逐层以值传递，控制流可读且无栈展开开销。
本例没有第三方依赖，用 `std::variant` 手写 `std::expected`（C++23）的最小
替身，语义一致：值在 0 号槽，错误在 1 号槽。

## 反例
`std::optional` 用来承载「失败原因」：只有「没有值」，无法区分
NotFound 和 Permissions，调用方只能猜；或者返回裸指针/哨兵值
（nullptr/-1）表示失败——调用方忘了检查，错误值就顺着管道流到下游。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
