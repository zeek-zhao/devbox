---
title: WALKTHROUGH · T-001-venv-mix-mutable-default（venv 串味、PEP 668 与可变默认参数排查）
track: python
lab: T-001-venv-mix-mutable-default
难度: P2          # P0–P5 刻度：双缺陷跨「环境维度 + 代码维度」，需 ruff/pip/venv/解释器自省四类工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 素材 S-13（虚拟环境串味）+ 类型②实验（可变默认参数与 PEP 668，复现命令见 §1）
verified_env: devbox-python:latest（Python 3.12.3 / pip 24.0 / ruff 0.17.4）
---

# WALKTHROUGH · T-001-venv-mix-mutable-default

> 依据 [docs/72 排障演练规范](../../../docs/72-排障演练规范.md) §4 编写；D1 拍板见
> [docs/73 §11](../../../docs/73-M11并发执行计划.md)。所有输出均为 2026-11-06 在
> devbox-python 容器内真跑所得（容器内临时构建目录已归一化为 `<BUILD>`，无内网信息）。
> `<BUILD>` = 容器内 `${TMPDIR:-/tmp}/devbox-python-T-001-venv-mix-mutable-default`。

## 1. 触发症状

在 devbox-python 容器内，lab 已把占位包 `myproj` 只放进 venvA 的 site-packages。
用 venvB 的解释器直跑（`bash repro.sh` 内部同款动作）：

```bash
docker run --rm -v "$PWD":/w -w /w ghcr.io/zeek-zhao/devbox-python:latest \
  bash python/examples/T-001-venv-mix-mutable-default/repro.sh; echo "rc=$?"
```

真实输出（类型②实验 + 来源：S-13，2026-11-06）：

```text
env: start
sys.executable=<BUILD>/venvB/bin/python
cart call1=['apple', 'banana']
cart call2=['apple', 'banana']
Traceback (most recent call last):
  File "/w/python/examples/T-001-venv-mix-mutable-default/main.py", line 38, in <module>
    sys.exit(main())
  File "/w/python/examples/T-001-venv-mix-mutable-default/main.py", line 33, in main
    print(f"myproj={load_myproj()}")
  File "/w/python/examples/T-001-venv-mix-mutable-default/main.py", line 21, in load_myproj
    import myproj
ModuleNotFoundError: No module named 'myproj'
rc=1
```

**症状一：装进 A 环境从 B 环境 import。** `import myproj` 在 venvA 里 rc=0、在 venvB 里
`ModuleNotFoundError`——同一份代码，唯一变量是解释器环境（素材 S-13 的正面现场）。

**症状二：PYTHONPATH 一指，串味成功。** `PYTHONPATH=<venvA 的 site-packages>` 后 venvB
照常 `import myproj` 成功，`myproj.__file__` 指向 venvA——依赖解析跟人走，跟环境无关
（S-13 的「没装也能 import」分支）。

**症状三：可变默认参数跨调用累积。** `cart call1` 与 `cart call2` 打印同一个列表
`['apple', 'banana']`——第二次调用把第一次的残留也带了回来，且第一次拿到的返回值
也被第二次调用污染。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | `echo $PYTHONPATH` | 空 | **非空且指向另一个 venv 的 site-packages** → 串味通道已找到（S-13 检查 3） |
| 2 | `"$VENV_B/bin/python" -c "import sys; print(sys.executable, sys.path)"` | 解释器与 sys.path 都只指向**同一个** venv | `sys.path` 里混进别的 venv，或解释器不是你以为的那个（S-13 检查 1 的容器内版） |
| 3 | `"$VENV_B/bin/python" -m pip list \| grep myproj; echo rc=$?` | `0`（当前环境确实没装，S-13 检查 2） | 装了还报 ModuleNotFoundError → 别急着重装，先走 §3 决策树 Q4 查 sys.path |

三条都只读：不改代码、不装包、不清变量。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 复跑一次，标记行 env: start 打印了吗？
├─ 没打印 → 文件路径/解释器不对（先排除「根本没跑起来」，不是代码问题）：
│     ls main.py; which python3   → 修调用方式/路径，不修代码
└─ 打印了 → Q1 有没有 Traceback？
    ├─ 有 → Q2 Traceback 尾行是什么？
    │   ├─ ModuleNotFoundError: No module named 'myproj'
    │   │     → Q3 这个解释器是谁？（看 sys.executable 行）
    │   │       ├─ 不是预期的 venv → 激活/调用错了环境，换对解释器重跑
    │   │       └─ 是预期的 venv → Q3' 包在这个环境里吗？
    │   │             ├─ pip list 里没有 → 包确实没装进这个环境（本 lab 现场）
    │   │             │     → 走 PEP 668 分支：系统层直接装会被拒，包装进 venv（§6）
    │   │             └─ 装了还报错 → Q4 sys.path 是否混入别的环境？
    │   │                   ├─ $PYTHONPATH 非空 → 清掉（unset PYTHONPATH）重跑
    │   │                   └─ 没设还混入 → 查 sitecustomize / .pth → 停止登记 UNVERIFIED
    │   │                         （本镜像未复现此分支）
    │   ├─ ImportError（非 No module named）→ 模块存在但内部出错，与本 lab 现场不符，
    │   │     停止并登记 UNVERIFIED 交维护者
    │   └─ 其他异常 → 与本 lab 现场不符，停止交维护者
    └─ 没有 Traceback，但 cart call1 与 call2 同为 ['apple', 'banana']
          → 代码维度缺陷：可变默认参数跨调用共享
            → ruff check --select B006 main.py 钉到定义行 → §6 修 None 哨兵
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-python 容器真跑）

### 4.1 Traceback（症状一）

- `sys.executable=<BUILD>/venvB/bin/python`：main.py 自报家门——这次 import 动作发生在
  venvB 的解释器里。**import 解析只看当前解释器的 sys.path，跟代码文件在哪个目录无关**；
- `File ".../main.py", line 21, in load_myproj` + `import myproj`：案发行。注意回调链
  38 → 33 → 21：崩溃点（print）与病因（import 解析）不在同一行，读 Traceback 要读**尾行**；
- `ModuleNotFoundError: No module named 'myproj'`：明确是「找不到模块」而非「模块内部出错」
  （那是 `ImportError`），语义上直接指向环境/安装维度。

### 4.2 串味铁证（症状二，`PYTHONPATH=$sp_a` 后 venvB 跑）

```text
myproj=1.0.0-venvA
myproj.__file__=<BUILD>/venvA/lib/python3.12/site-packages/myproj.py
```

- venvB 的解释器、没装过 myproj，却 import 成功且 `__file__` 指向 **venvA** 的
  site-packages——这就是 S-13 说的「装进 A 环境从 B 里 import」的完整闭环；
- 判读要点：串味不是「版本对不上」的普通依赖问题，而是**搜索路径被污染**。
  `echo $PYTHONPATH` 一条命令即可定通道；清掉通道后症状应立即回到 4.1。

### 4.3 PEP 668 防线（step 6，系统解释器直接 pip install）

```text
error: externally-managed-environment
╰─> To install Python packages system-wide, try apt install
```

- 系统解释器带 `EXTERNALLY-MANAGED` 标记（`/usr/lib/python3.12/EXTERNALLY-MANAGED`），
  pip 在**解析包名之前**就直接拒绝——所以用假包名也能稳定触发，输出可作断言锚点；
- 判读要点：**这是防线不是故障**。它存在的意义是逼你把包装进 venv；绕过它要用
  `--break-system-packages`（污染系统层，排障场景下永远是最后手段）。

### 4.4 ruff --select B006（症状三的静态定位）

```text
B006 Do not use mutable data structures for argument defaults
  --> python/examples/T-001-venv-mix-mutable-default/main.py:13:28
   |
13 | def build_cart(item, items=[]):
   |                            ^^
help: Replace with `None`; initialize within function
```

- 默认规则集（E/F/W）对此**全绿**——B006 属 flake8-bugbear，不在默认集；所以
  「lint 绿」不能当结案证据，要按缺陷类型换检测器（run.sh step 1/2 的对照设计）；
- `main.py:13:28` 把缺陷钉到 `items=[]` 的定义表达式本身，还直接给出 None 哨兵修法。

### 4.5 运行时残留（症状三的行为证据）

```text
cart call1=['apple', 'banana']
cart call2=['apple', 'banana']
```

- 默认参数 `items=[]` 在 `def` 执行时创建**一次**，之后所有调用共享同一个列表对象；
  `cart1` 与 `cart2` 是同一个引用，所以两行打印相同；
- 关键读法：**第一次调用的返回值也被第二次调用污染**（call1 里出现了 banana）——
  这说明不是「打印了同一个变量」的展示问题，而是默认对象跨调用被写坏。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑（venvB 解释器直跑 main.py）：

> **预测**：`build_cart("apple")` 后再 `build_cart("banana")`，两次调用各返回什么？
> （多数人预测：call1=['apple']，call2=['banana']。）

**观察**（真实输出）：

```text
cart call1=['apple', 'banana']
cart call2=['apple', 'banana']
```

**explain 落差**：默认参数求值发生在函数**定义**时而非每次调用时，`[]` 是全函数共享的
单一对象。第一行最反直觉——不是 call2 带了残留，而是 call1 与 call2 从头到尾就是同一个
列表。静态上 ruff B006 钉到 `items=[]`（§4.4），行为上两次调用打印同一对象（§4.5），
两份独立证据互相印证。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | `ModuleNotFoundError` 是代码 bug（import 写错了） | 模块名拼写不一致；或换任何环境都报同样的错 | import 拼写正确（main.py:21 `import myproj`）；venvA 跑同一份代码 rc=0 且 `myproj=1.0.0-venvA` | 排除：代码没变、变的只是解释器环境，问题在环境维度 |
| H2 | venvB 里其实装了 myproj（版本/损坏问题） | `pip list` 能看到 myproj | `pip list \| grep myproj` 无输出（rc=1，当前环境确实没装） | 排除：包根本不在 venvB |
| H3 | 串味通道是 sitecustomize / .pth（装包时自动埋的） | 串味与 PYTHONPATH 无关；venvB site-packages 里能找到 .pth | 串味**只在** PYTHONPATH 指向 venvA 时发生；清掉后立即回到 ModuleNotFoundError | 排除：通道就是 PYTHONPATH 环境变量 |
| H4 | cart 两行相同只是因为打印了同一个变量（展示问题，不是缺陷） | 换个接收变量再调一次，应得到干净的新列表 | None 哨兵修复版跑出 call1=['apple'] / call2=['banana']（§6），B006 也把病灶钉在默认值表达式 | 排除：默认对象跨调用共享且被写坏，是真实缺陷 |

## 6. 改动后验证

修复分两个维度，在**副本**上做（别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）。

**修复 1（代码维度）：可变默认参数 → None 哨兵。**

```python
def build_cart(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

2026-11-06 修复版真跑（健康对照）：

```text
fixed call1=['apple']
fixed call2=['banana']
```

静态复查同维度：`ruff check --select B006 fixed_cart.py` → `All checks passed!`（rc=0），
对照 §4.4 的 `Found 1 error`。

**修复 2（环境维度）：把包装进正确的 venv（或清掉串味通道）。**

```bash
BUILD="${TMPDIR:-/tmp}/devbox-python-T-001-venv-mix-mutable-default"
cp "$BUILD/myproj.py" "$(ls -d "$BUILD"/venvB/lib/python3*/site-packages | head -1)/"
"$BUILD/venvB/bin/python" python/examples/T-001-venv-mix-mutable-default/main.py; echo "rc=$?"
```

2026-11-06 修复版真跑：

```text
cart call2=['apple', 'banana']
myproj=1.0.0-venvA
rc=0
```

（cart 两行仍带残留——那是缺陷 2 的现场，本步不改它；本步只验证 import 维度转绿。）
日常写法统一 `python3 -m pip`（保证 pip 与解释器同环境，S-13 修复建议），系统层直接装
则被 PEP 668 拒绝（§4.3，属预期防线）。

两个维度都绿 = 修好；只看「不崩」不算——还要看标记行、cart 残留与 B006 各自的判据。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `python3` / `pip` / `ruff` 任一 `command not found`，或 `python3 -m venv` 创建失败（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. venvA 都报 `ModuleNotFoundError`（健康对照也红了 → 镜像/site-packages 布局漂移）；
4. PEP 668 分支报的是 `ImportError` 或其他类型异常，与本 lab 现场不符；
5. 需要修改 `python/examples/T-001-venv-mix-mutable-default/` 目录之外的文件才能继续；
6. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-python:latest 容器（Python 3.12.3 / pip 24.0 /
ruff 0.17.4，Docker on Linux）。`run.sh` 连跑 2 次、`assert.sh` 连跑 2 次，结论均一致
（RUN-PASS 7/7、ASSERT-PASS）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| `.pth` / sitecustomize 通道的串味（决策树 Q4 右枝） | UNVERIFIED | 本镜像未构造该现场，只验证了 PYTHONPATH 通道 | 做变体 lab 时在 venvB site-packages 放 .pth 补验 |
| `--break-system-packages` 强装系统层的后果链 | UNVERIFIED | 防线语义已验（§4.3），故意污染系统层不在本 lab 射程 | 维护者如需演示可加 challenge 变体 |
| pip 与 python 不同环境的 `which python3 / which pip` 分叉现场（S-13 检查 1 的宿主版） | UNVERIFIED | 容器内两者同源于 3.12，分叉需专门构造 | 换基础镜像时顺带复跑 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **来源：S-13**（docs/24-G3素材池.md）：虚拟环境串味——§1 症状一/二、§2 三条只读检查、
  §3 决策树 Q3'/Q4、§4.2 的 `myproj.__file__` 铁证均按该素材的现场与检查清单落地；
- **类型②实验**：§1 症状三、§4.3、§4.4、§4.5 与 §6 全部现象为 2026-11-06 在
  devbox-python 容器内真跑所得，复现命令即 §1 与 `repro.sh`；输出已归一化
  （容器内临时构建目录 → `<BUILD>`），不含内网信息。
