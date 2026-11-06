# E-009-leak-guard

## 现象
`FILE*` 包进 `unique_ptr` + 自定义删除器：正常路径 done 后关闭一次；
读一半抛异常的路径，closed 出现在 caught **之前**（展开时守卫关闭）；
打不开文件的路径根本不产生句柄。三条路径都恰好关闭/失败一次。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-009-leak-guard
```

## 期望输出
```text
opened /tmp/devbox-e009-good.txt
read_header: processing /tmp/devbox-e009-good.txt
read_header: done
closed
opened /tmp/devbox-e009-bad.txt
read_header: processing /tmp/devbox-e009-bad.txt
closed
bad path: caught bad header
missing path: caught cannot open /tmp/devbox-e009-missing.txt
```

## 为什么
泄漏的根源是「获取与释放之间有 N 条退出路径」，手写 close 就要覆盖
return、throw、break 每一条。unique_ptr 把释放绑到析构上，退出路径
加多少都不用改清理代码；自定义删除器让 fclose 这种非 new 资源也能
托管。valgrind/ASan 对三条路径都报不出泄漏——这是「防护」的可验证
判据，而不是口头承诺。区别于 E-004（析构逆序）：这里讲的是所有权
移交与「恰好一次」释放，不展开顺序问题。

## 反例
`auto* f = fopen(...); process(f); fclose(f);`——process 一抛，fclose
成死代码，句柄泄漏；或者 finally 式补丁：每个 catch 里都写一遍 fclose，
新分支漏写一处就漏一次；或者 unique_ptr 用了 `delete` 默认删除器去关
FILE*（未定义行为，不是 fclose 语义）。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
