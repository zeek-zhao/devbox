# C++ 毕业项目：用例覆盖表

本表记录已落地用例及其代码位置，由 `scripts/coverage-check.sh cpp` 校验用例存在性和代码引用。当前只登记已经存在的 `hello` 用例。

## 怎么加一行

1. 在实现或测试代码中用注释写上对应的用例 ID；校验会在代码中查找 ID（不检查本表自身），以避免覆盖表只靠自己的声明“自证”。
2. 在下面的覆盖表中增加该用例的一行，并填写准确的文件位置和说明。
3. 运行 `bash scripts/coverage-check.sh cpp` 自检，确认示例目录中的用例均有对应声明和代码引用。

## 覆盖表

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.cpp:2 | 保留阶段 0 的基础用例引用 |

## 自检

bash scripts/coverage-check.sh cpp

## pending：用例已落地但项目还没接入

阶段 2 铺开 53 个用例时，项目骨架只真实用到 `hello` 一个。用例若还没被 `project/` 引用，
就在它自己的 `README.md` 里写一行：

```markdown
<!-- coverage: pending -->
```

`scripts/coverage-check.sh` 会对这类用例豁免「必须在表里声明」和「必须在代码里出现」两条，
但会单独统计并打印 pending 数量 —— 它是**明账上的欠债，不是通过**。
阶段 4 收口时用 `bash scripts/coverage-check.sh --strict`，pending 未清零即失败。
