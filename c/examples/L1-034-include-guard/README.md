

# L1-034-include-guard —— 用宏保护处理循环包含

## 考点

- `#ifndef` / `#define` 头文件保护避免同一头文件重复展开。
- 经由中间头文件形成的循环包含可在保护宏作用下正常终止。

## 为什么这么写

`a.h` 包含中间头，中间头包含 `b.h`，而 `b.h` 又包含 `a.h`；主文件还显式包含两个头，验证保护宏能阻止重复定义。

## 易错点

- 保护宏必须在头文件主体内容之前定义。
- `#pragma once` 不属于 ISO C 标准，本例使用标准预处理指令。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-034-include-guard
```
