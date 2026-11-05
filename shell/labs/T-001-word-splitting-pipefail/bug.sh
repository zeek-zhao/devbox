#!/usr/bin/env bash
# T-001-word-splitting-pipefail 练习现场（有缺陷代码，勿模仿）。
# 缺陷 1：变量不加引号展开 → 分词：含空格的文件名被拆成两个参数。
# 缺陷 2：管道吞错：没设 set -o pipefail，左侧失败被右侧成功掩盖。
# 注意：本文件是「分析标本」，仓库级 shellcheck 门禁（-S warning）对本文件
# 退出 0——SC2086 在 shellcheck 0.9 里是 info 级，低于 warning 阈值；run.sh
# 第一步用默认 severity 把它显式打出来。
work="${TMPDIR:-/tmp}/devbox-shell-T-001-fixture"
mkdir -p "$work"
printf 'alpha\nbeta\ngamma\n' >"$work/report final.txt"
printf 'delta\n' >"$work/notes.md"

echo "split: start" # 执行标记：证明脚本真的被跑过（素材 S-06）

# 缺陷 2 现场：grep 因文件不存在而失败，wc 成功 → 管道 rc=0
count=$(grep -c 'alpha' "$work/missing-deploy.log" 2>/dev/null | wc -l)
echo "pipeline: matched=$count rc=$?"
if [ "$count" -eq 0 ]; then
  echo "pipeline: 判定为无匹配（真相：左侧 grep 因文件不存在整体失败，被 wc 吞掉）"
fi

# 缺陷 1 现场：$target 不加引号 → 分词
target="$work/report final.txt"
echo "split: 想统计这个文件的行数 [$target]"
lines=$(wc -l $target 2>/dev/null)
echo "split: lines=[$lines]"
wc -l $target # 本脚本的退出码 = 这条命令：分词后两个参数都不存在，rc=1
