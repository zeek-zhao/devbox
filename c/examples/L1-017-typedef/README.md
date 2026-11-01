

# L1-017 —— typedef 与不透明类型

`typedef struct foo foo_t;` 为同一个类型提供别名，不会创建新类型。真实的多文件设计会
把该声明和 API 放在头文件中、隐藏 `struct foo` 的定义；为满足 L1 单文件约束，本例将
接口、实现和 `main` 放在一起，而 `main` 仅持有 `foo_t *` 并调用公开函数。因而
`const foo_t *` 与 `const struct foo *` 是同一种类型。
