# SOLUTION · T-001-venv-mix-mutable-default（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-python 容器真跑（容器内临时构建目录归一化为 `<BUILD>`）。

## 1. 为什么「一模一样的环境」一个崩一个不崩？

环境不一样。`sys.executable` 自报家门是第一证据：

```text
sys.executable=<BUILD>/venvB/bin/python
ModuleNotFoundError: No module named 'myproj'
```

venvA 跑同一份代码：rc=0、`myproj=1.0.0-venvA`。import 解析只看**当前解释器**的 sys.path，
与代码写在哪个目录无关——所以先查环境，再谈代码（这是 H1 被否决的过程）。

串味通道验证：`PYTHONPATH=<venvA site-packages>` 后 venvB import 成功，且

```text
myproj.__file__=<BUILD>/venvA/lib/python3.12/site-packages/myproj.py
```

包明明在 venvA，venvB 却借到了——S-13「装进 A 环境从 B 里 import」的闭环。

## 2. 两行相同的列表是什么缺陷

可变默认参数。静态定位（换检测器，默认规则集是绿的）：

```text
B006 Do not use mutable data structures for argument defaults
  --> python/labs/T-001-venv-mix-mutable-default/main.py:13:28
13 | def build_cart(item, items=[]):
```

行为证据：默认对象在 def 时创建一次、所有调用共享，所以 call1 的返回值也被第二次
调用污染（call1 里出现了 banana）——不是展示问题，是跨调用状态泄漏。

（另：系统层 `python3 -m pip install ...` 会撞上 `externally-managed-environment`——
这是 PEP 668 防线，不是故障；它逼你把包装进 venv。）

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 代码 bug（import 拼错）？→ 拼写正确且 venvA 同代码 rc=0 → 否，环境维度。
- H2 venvB 装了包但损坏？→ `pip list | grep myproj` 无输出 → 否，根本没装。
- H3 串味是 sitecustomize/.pth？→ 只有 PYTHONPATH 指向 venvA 时才串味 → 否。
- H4 两行相同只是打印同一变量？→ None 哨兵修复版 call1=['apple'] / call2=['banana']，
  B006 钉到默认值表达式 → 否，默认对象跨调用共享。

## 4. 修复 diff 与验证

```diff
-def build_cart(item, items=[]):
+def build_cart(item, items=None):
+    if items is None:
+        items = []
     items.append(item)
     return items
```

环境维度：把 myproj 装进正确的 venv（`python3 -m pip` 统一写法，或入位 site-packages），
或清掉杂散 `PYTHONPATH`。

验证（2026-11-06 修复版真跑）：

```text
fixed call1=['apple']          # 可变默认参数修复后
fixed call2=['banana']         # ruff --select B006 → All checks passed!（rc=0）

myproj=1.0.0-venvA             # myproj 入位 venvB 后，venvB 解释器跑 main.py rc=0
rc=0
```

两个维度都绿才算修好；把改动落到 lab 的 main.py 前先想清楚——那是缺陷现场，
assert.sh 按设计断言「故障在场」，修了它 lab 就废了。
