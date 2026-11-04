---
track: java
guide: G5
dimensions: [D2, D5, D8]
level: P2
status: draft
links: [知识点清单.md, 开发指南.md, 工具指南.md]
examples: [L1-031-volatile-publication, L2-008-files-utf-eight, L3-002-virtual-threads]
---

# Java 轨道 G5 FAQ

> 按主题分组的高频短问答。每条给结论、一步命令与出处；
> 「详见 G3」指 `java/docs/问题指南.md`——**该文件属 M8，尚未建立**，链接到位前只给 G4/G2 出处。

## 环境与运行

### Q: 为什么宿主上跑不了用例，一定要进容器？
A: 结论：JDK 与格式化器只装在 `ghcr.io/zeek-zhao/devbox-java:${TAG:-latest}` 镜像里，宿主不保证有。一步命令：`TAG=latest scripts/run-example.sh java L0-hello`（runner 自动起容器）。详见 G2 §1。

### Q: 镜像 tag 该写 latest 还是 local？
A: 结论：文档与 CI 统一 `TAG=latest`；宿主已有本地构建的同名镜像时，本地调试把 `TAG` 换成 `local`。不要在文档里硬编码任何 tag（命令契约）。详见 G2 §3。

### Q: 用例 PASS 但和 CI 结果对不上，先看什么？
A: 结论：先确认镜像一致，再确认 `expected.txt` 未被本地改过。一步命令：`docker image inspect ghcr.io/zeek-zhao/devbox-java:${TAG:-latest} --format '{{.Id}}'`。详见 G2 §3。

## 编译与构建

### Q: 打包后 java -jar 报找不到辅助类（NoClassDefFoundError）？
A: 结论：多半只把入口 class 打进去了。一步命令：`jar --list --file app.jar` 核对内容，从完整输出根目录 `jar --create --file app.jar --main-class app.Main -C out .` 重打。见 `L2-003-executable-jar`；工具速查详见 G4 §2.2。

### Q: 怎么确认编译出来的字节码真的是 21 级别？
A: 结论：看 major version（21 → 65）。一步命令：`javap -verbose -classpath out app.Main | grep 'major version'`。见 `L2-002-compile-bytecode`；详见 G4 §2.4。

### Q: javadoc 生成时 @param 对不上签名就失败，能关掉吗？
A: 结论：不关——本工程口径是 `-Xdoclint:all -Werror`，标签与签名必须同步维护。一步命令：`javadoc -quiet -Werror -Xdoclint:all -d api -sourcepath src devbox.rest`。见 `L2-004-api-javadoc`；详见 G4 §2.5。

### Q: 格式检查在宿主上报 command not found？
A: 结论：google-java-format 只在镜像里，宿主直跑必然失败。一步命令：`bash scripts/fmt.sh --lang java`（脚本自己进容器；版本由 `${GJF_VERSION}` 锁定）。详见 G2 §4、G4 §2.8。

## 并发与 JVM

### Q: volatile 变量计数还是丢更新，是 volatile 坏了吗？
A: 结论：不是——volatile 只保证可见性，`++` 仍是读改写三步。计数改用 `AtomicInteger` 或锁。一步命令：`javap -c` 看自增是否拆成多条指令（见 `L1-031-volatile-publication`）。排查路径详见 G4 §2.6。

### Q: 虚拟线程是不是就不用同步了？
A: 结论：不是——虚拟线程只改调度，不改变内存可见性与竞态规则，共享状态照旧要同步。一步命令：`TAG=latest scripts/run-example.sh java L3-002-virtual-threads`（该例演示失败收集与显式等待）。详见 G4 §2.6。

### Q: 线程卡死怎么抓现场？
A: 结论：优先 `jcmd <pid> Thread.print`（比 jstack 更可靠），多次采样对比，死锁看互等 lock 的闭环。一步命令：`jcmd $(jps | awk '/Main/{print $1}') Thread.print | head -50`。详见 G4 §2.6 与 §4 误用 2；G3（M8）建立后在此处补「并发」问题域链接。

## 文本与编码

### Q: 容器里读写中文文件乱码怎么办？
A: 结论：不用平台默认编码，显式 `StandardCharsets.UTF_8` 读写。一步命令：`TAG=latest scripts/run-example.sh java L2-008-files-utf-eight`（中英文本 UTF-8 往返用例）。详见 G4 §4 误用 4。

### Q: 时间戳进 expected.txt 为什么会被打回？
A: 结论：时间、PID、线程 ID、地址、绝对路径都不进 expected（清单口径）——它们随环境变。比较时间用显式 `ZoneId`，测试断言只写确定值。详见 `java/docs/知识点清单.md` §1 的验收规则。

## 查不到时去哪查

1. 本仓库 [ROADMAP](../../docs/ROADMAP.md) 的 KI 段——已知问题与历史 bug（含 `:latest` 并发污染等）先查这里；
2. `java/docs/知识点清单.md`——找考点对应的用例 ID，再按 ID 跑用例复现；
3. `java/docs/工具指南.md` §4——Java 特有坑（OOM 分类、死锁、类加载、时区与默认编码）的速查；
4. 上游文档与 issue 搜索：OpenJDK 官方工具文档，以及仓库 issue 按关键词（如 `devbox-java OOM`）搜索；
5. 问题指南（G3）属 M8 计划，建立前请勿在本文件添加指向它的链接。
