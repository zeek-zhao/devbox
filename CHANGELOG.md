# Changelog

本文件由 `npx @zeek/release` 生成，请勿手改。

## [0.1.0](https://github.com/zeek-zhao/devbox/compare/v0.1.0^...v0.1.0) (2026-11-15)

### ✨ Features | 新功能
* add README coverage advisory and expected-error contrasts (#399 #400)
* shell 轨知识点补齐 53→70，同步全仓口径 804→821（#396）
* 搭建六语言学习仓库骨架与分层镜像体系
* 文档死链/层配比/毕业项目验证/读者路径四项落地，db 补齐 G2+G4（#393 #394 #395 #397 #398）
* **c**: 补齐 C 语言 L1 用例后一半（17 例，L1-018 ~ L1-034） (#152)
* **c**: 补齐 C 语言 L1 语言特性用例（前 17 例） (#150)
* **c**: 补齐 C 语言 L2 工程能力用例（20 例） (#153)
* **c**: 补齐 C 语言 L3 专题用例（23 例） (#157)
* **cpp**: 把 L1 的 35 个用例接进毕业项目（pending 76 → 41） (#156)
* **cpp**: 把 L2/L3/L4 的 41 个用例接进毕业项目（pending 41 → 0） (#158)
* **db**: 新增数据库学习轨道骨架（77 例）+ 版本管理工具骨架 (#159)
* **db**: 毕业项目「带缓存的订单服务」，覆盖 56/77 用例 (#166)
* **db**: 真拓扑补强（Redis 集群 MOVED/ASK/故障切换、真实计数器）+ 21 条 pending 收口
* **db**: 补齐 L2 工程能力后半 + L3 专题（19 例） (#163)
* **db**: 补齐 L4 数据设计用例（10 例） (#164)
* **db**: 补齐 MongoDB + Redis 的 L1 用例（16 例） (#161)
* **db**: 补齐 MySQL + SQLite 的 L1 用例（16 例） (#160)
* **db**: 补齐 PostgreSQL 的 L1 用例 + L2 工程能力前半（16 例） (#162)
* **fmt**: 引入统一格式化基线（配置 + fmt.sh + 镜像补 clang-format/gjf/yq） (#146)
* **go**: L4 设计模式用例接入毕业项目（9 例真接入 + 14 例豁免）
* **images**: 容器默认以非 root 用户运行，工具预装进镜像，修掉 :latest 并发污染
* **java**: L4 设计模式用例接入毕业项目（8 例真接入 + 15 例豁免）
* **l4**: cpp 设计模式用例 L4-001..L4-012（12 例）
* **l4**: cpp 设计模式用例 L4-013..L4-023（11 例）
* **l4**: go 设计模式用例 L4-001..L4-012（12 例）
* **l4**: go 设计模式用例 L4-013..L4-023（11 例）
* **l4**: java 设计模式用例 L4-001..L4-012（12 例）
* **l4**: java 设计模式用例 L4-013..L4-023（11 例）
* **l4**: python 设计模式用例 L4-001..L4-012（12 例）
* **l4**: python 设计模式用例 L4-013..L4-023（11 例）
* **lang**: 新增 Vue 镜像 + C 复用 cpp 层（9 个门禁点） (#148)
* **m4**: Go 并发任务网关（标准库）与用例覆盖闭环
* **m4**: Java JDK HttpServer REST 服务（无 Maven）
* **m4**: Python CSV 数据处理与报表
* **m4**: Rust 跨平台 CLI 工具（仅标准库）
* **m4**: Shell 部署与巡检工具集
* **m4**: scripts/checkpoint-M4.sh 六项目收口检查点
* **m4**: 进度看板 R-W-05（自包含 HTML，零 CDN，双主题）
* **python**: L4 设计模式用例接入毕业项目（9 例真接入 + 14 例豁免）
* **release**: 实现 @zeek/release 版本管理工具 (#165)
* **rust**: 用例从 51 补到 74，全部真接入毕业项目
* **scripts**: add M1 checkpoint automation (#10)
* **shared**: 把 base-sample 的可复用 shell 脚本整理成 shared/ 工具箱 (#149)
* **vue**: 用例从 46 补到 74，能接的接项目，接不上的写清理由
* **vue**: 补齐 Vue L1 语言与框架基础用例（18 例） (#151)
* **vue**: 补齐 Vue L2 工程能力用例（15 例） (#154)
* **vue**: 补齐 Vue L3 专题用例（12 例） (#155)

### 🐛 Bug Fixes | Bug 修复
* 修 CI 三处真红灯 + 补门禁守卫与本地钩子
* **board**: 看板门禁合成一步，并修掉两处「手工维护」的过时注释
* **ci**: aggregate job 补齐 all/runtime 体积记录，回填 R-I-02 预算表
* **ci**: push 时同时打 latest tag，修镜像拉不到的问题
* **ci**: verify-projects 在 CI 内拉取 sha 镜像，禁止静默回退宿主（#394）
* **coverage**: 覆盖判据只认非 md 文件，堵掉「README 表格自证」
* **db**: L2-10 的就绪门改成「连续 3 次成功 + 走 TCP + 失败留证」
* **db**: 补上两处 cd 的失败处理，让 main 的 shellcheck 门禁变绿
* **db**: 让用例失败不再是静默的
* **docs**: 看板数据对齐实况 + 加防漂移门禁
* **images**: MAVEN_OPTS 走 ARG，修真本与镜像不一致 (#4)
* **images**: buildx 不认 --build-arg-file，且 CI 上用官方 apt 源
* **images**: python 运行时基础镜像改用 python3，体积 384MB 达预算
* **images**: shell 层改用 util-linux-extra 提供 getopt
* **images**: tool 层去掉 heredoc，配置文件改为 COPY；修 apt 源空值语义
* **oss**: 修 Issue 模板的 YAML 语法，GitHub 才认
* **release**: 修 lastTag/repositoryUrl/CHANGELOG 五处缺陷，测试 42→59
* **runner**: run-example.sh 同时认 TAG 与 IMAGE_TAG，修用例测试拉不到镜像
* **shell**: L3-013 run.sh 未用循环变量触发 SC2034（#396）
* **verify**: 镜像探测失败后先 docker pull 再判（#394，attempt2 教训）

### ✏️ Documentation | 文档
* 11 §3 翻转为 A+C 方案（M11-G-335）
* 80 trace schema 补 E 类执行留痕扩展块 e_example（M12-M-344）
* 80 增补 E 类六例 golden set 回放基准（M12-M-345）
* 81 错误处理四模型与分类法（M11-G-329）
* 82 错误码与错误结构（M11-G-330）
* 83 排障总入口（M11-G-331）
* 84 文档地图（M11-G-332）
* 85 CI 增强规格施工图（M12-CI-340）
* 86 度量口径（仓库资产侧六指标）（M12-M-343）
* 87 CI 失败取证规范（M12-CI-342）
* E 类批次终段集成——口径 719→794 + 看板重生成（M11-INT 终段，#336）
* E 类批次集成——口径 659→719 + 看板重生成（M11-INT，#336 前段）
* M11 验收报告 + 16 卡执行 trace（M11-W4-265）
* M11-INT 终验回写 794 口径与状态快照（M11-INT-336）
* M11-W4 集成回写：批次实际结果与 API 实测状态（M11-W4-266）
* M11/M12 GATE 拍板结论落地 + CI 增强验收报告（#267 #277 #346）
* PR 模板补 spec v2 四段 + 建文档健康规范（M11-W0-03）
* Q-R-01~08 逐条拍板结论写进 40 §0.2（M9-GATE #224）
* c 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-c）
* cpp 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-cpp）
* db 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-db）
* go 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-go）
* go 错误处理指南 frontmatter examples 补全 + 索引保鲜（M11-DOC-go-fix-389）
* java 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-java）
* python 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-python）
* rust 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-rust）
* shell 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-shell）
* vue 轨知识点清单 E 段 + 三篇指南 + 轨道索引（M11-DOC-vue）
* 修正 runtime 层 python 描述（对齐 Q-S-08 口径与容器实测）
* 全站索引 INDEX（M11-G-333）
* 同步项目状态到 659 例，KI-03/KI-05 收口，KI-07 改成 toolbox 仍 root
* 回写 W5 完成状态与分支清理留痕（30/70/ROADMAP）
* 定稿 9 轨道开发发布增强表（M9-03）
* 已知问题挂上 GitHub Issue 编号，状态以 Issue 为准
* 建 C 轨道 G1/G3（M8-03）
* 建 C 轨道 G2/G4/G5 最小集（M7-01）
* 建 C++ 样板五篇指南（G1-G5，M6-05）
* 建 CI 失败分类规范（M12-W1-01）
* 建 G3 真实排查素材池（M8-02）
* 建 Go 轨道 G1/G3（M8-05）
* 建 Go 轨道 G2/G4/G5 最小集（M7-02）
* 建 Java 轨道 G1/G3（M8-09）
* 建 Java 轨道 G2/G4/G5 最小集（M7-06）
* 建 M11 派单状态表（M11-W0-04）
* 建 M11 里程碑与 15 张 spec v2 卡，落地任务卡表单与并发计划
* 建 M12 度量规范与 trace schema（M12-W2-01）
* 建 M6-M10 里程碑与 45 张任务卡，回写远端状态
* 建 Python 轨道 G1/G3（M8-08）
* 建 Rust 轨道 G1/G3（M8-06）
* 建 Rust 轨道 G2/G4/G5 最小集（M7-03）
* 建 Shell 轨道 G1/G3（M8-07）
* 建 Shell 轨道 G2/G4/G5 最小集（M7-04）
* 建 Vue 轨道 G1/G3（M8-11）
* 建 Vue 轨道 G2/G4/G5 最小集（M7-08）
* 建 db 轨道 G1/G3（M8-10）
* 建任务卡规范 v2（M11-W0-01）
* 建发布工程七域文档（R1-R7，M9-02）
* 建排障演练规范（M11-W0-02）
* 建文档健康 advisory 清单（M12-W1-03）
* 建通用开发指南（T0 骨架，M6-03）
* 按工程实测收口 v0.2.0 与 M6-M10 并回写状态文档
* 按用例反查索引规范与样例（M11-G-334）
* 教学形态对标调研——本仓「跑正确代码」vs rustlings「改坏代码」
* 社区入口——写卡指南 + labs 入口（M11-W2-10）
* 素材池追加 S-09~S-14 六个语言级排障案例（M11-W2-09）
* 落地 D1-D5 决策，M11 扩到 19 张卡并补并发治理
* 落地 E1-E7 决策，新建 M12 里程碑与 6 张卡并回写状态
* 补建 M0-M5 里程碑、关闭收尾卡，新增并行 AI 开发计划
* 补齐六个 hello 用例的考点说明 (#2)
* 记录外部镜像源抖动导致 db 用例假失败的取证链
* 轨道表与目录说明对齐 PROJ-C / PROJ-VUE 落地后的事实
* 重生成站点索引纳入 85/86/87（M12-CI-339 保鲜契约）
* **c**: 补用例编写规范与知识点清单
* **l4**: 四语言设计模式专题骨架（23 模式 × cpp/go/python/java）
* **m4**: 根 README 更新到 M3 完成后的真实状态
* **m4**: 用例编写规范补 pending/执行位/离线构建三节
* **oss**: 加 Apache-2.0 许可证、社区文件与开源合规审计
* **oss**: 审计报告的流水线实测补上第三轮，写清 12–21 分钟的区间
* **oss**: 按第 6 节独立重跑，修两处经不起重跑的表述
* **oss**: 补第五轮实测 —— 就绪门修完后 33/33 全绿
* **python**: 补 KP-PY-L1-32（functools.lru_cache）使 python 用例数达 50 (#60)
* **vue**: 补用例编写规范与知识点清单

### 💄 Styles | 风格
* 全量格式化六门语言 + fmt-check 接入 CI 阻断 (#147)

### ♻️ Code Refactoring | 代码重构
* 排障演练 labs 迁入 examples/ 并同步全仓口径 794→804（#390）
* **naming**: hello 改名为 L0-hello，L0 定义为通路验证层

### 📦 Build System | 打包构建
* **board**: 进度看板改成生成物，CI 校验重新生成后无差异

### 👷 Continuous Integration | CI 配置
* action 升级 Node24 原生 major 并重钉 SHA；examples 矩阵 artifact 名加 matrix.lang（#391 #392）
* labs job 对无镜像层轨道（shared 等）改为 runner 直跑（#276 归口）
* labs job 改 needs 结构化等待 images（修首次运行预算误判）
* release 自测改用 glob —— node 22 起不接受目录参数
* 修 labs job 无镜像层守卫的判断次序（#276 后续）
* 修 labs 脚本 shellcheck SC2027/SC2086（引号内插规范化）
* 修复 classify-ci-failure.sh 的 shellcheck SC2066/SC2034（M12-CI-338 修复）
* 发版档覆盖校验改 --strict，日常档仍容忍明账 pending
* 把 release 工具自测接进 fast / full 两档
* 新增 CI 失败三分类脚本（M12-CI-338）
* 新增 E 类示例契约校验脚本（M12-CI-337）
* 新增三层索引生成脚本 build-doc-index.sh（M12-CI-339）
* 流水线分三档（PR 不跑 / main 跑快档 / tag 跑全量）+ 合并前总闸
* 门禁批次四项——索引保鲜门 / E 类契约门 / action 固定 SHA / 失败取证留档（#341）
* **images**: 新增 budget job，体积超预算 15% 即流水线失败 (#9)
* **oss**: 流水线合并为一档全量 + 提交身份门禁
