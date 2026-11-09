# E-003-catch-order —— 多 catch 顺序与联合捕获

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-003 多 catch 顺序与联合捕获），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

多个 catch 子句里把父类写在前面：`catch (IOException)` 排第一，
`catch (FileNotFoundException)` 就成了不可达代码——编译器对「子类跟在
父类后」直接报错，但对「把能并到一起的处理散成重复块」毫无反应，
后者靠约定维持。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-003-catch-order
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-003-catch-order \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：具体类型 FileNotFoundException 先命中；
非子类关系时父类捕获兜底；FileNotFoundException 与
InterruptedIOException 用联合捕获 `|` 走同一处理器；末行固定输出顺序规则。

## 为什么这样处理

- catch 按书写顺序自上而下匹配：子类处理器必须写在父类之前，
  否则 javac 直接报「已由前一个子句处理」（编译期就把死代码拦住）。
- 处理方式相同的同级类型用联合捕获 `catch (A | B e)`：减少重复块；
  联合参数隐式 final，能安全地在 lambda / 匿名类里引用。
- 处理方式不同的父子类型分开写：为了「少一个块」把不同策略并进
  父类 catch，会丢失精确处理能力。

## 反例

- 把所有异常都并进 `catch (Exception e)`：类型信息归零，分流无从谈起。
- 联合捕获里再 `instanceof` 分叉且分叉策略完全不同：应该拆成两个 catch。
- 依赖「父类 catch 在前也能跑」的经验：在新版本编译器/严格模式下
  直接编译失败，属可预期的红灯而非玄学。
