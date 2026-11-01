<!-- coverage: pending -->

# L1-019-compound-literals —— 直接构造并传递结构体值

## 考点

- 复合字面量能在表达式中构造指定类型的对象。
- 构造出的结构体值可以直接传给按值接收的函数。

## 为什么这么写

将 `(struct point){1, 2}` 直接传入打印函数，避免额外命名变量，让输出确实来自复合字面量构造的值。

## 易错点

- 块作用域内的复合字面量具有自动存储期，不要返回其地址供作用域外使用。
- 复合字面量的类型名不能省略。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-019-compound-literals
```
