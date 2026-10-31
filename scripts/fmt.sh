#!/usr/bin/env bash
# ==================================================================
# 统一格式化入口（唯一真本：make fmt / make fmt-check 都走这里）
# ------------------------------------------------------------------
# 为什么必须走容器：
#   clang-format / google-java-format / prettier 只装在各自的语言镜像里，
#   宿主（Windows 开发机、215 构建机）上一个都没有。宿主直跑必然
#   command not found —— 所以格式化器和被测代码一样，只能活在镜像里。
#
# 用法：
#   bash scripts/fmt.sh                 # 就地格式化全部语言
#   bash scripts/fmt.sh --check         # 只检查不改写；有差异 exit 1（CI 用这个）
#   bash scripts/fmt.sh --lang cpp,go   # 只处理指定语言
#   bash scripts/fmt.sh --list          # 打印语言 -> 工具映射，永不失败
#
# 环境变量：
#   REGISTRY   镜像仓库前缀，默认 ghcr.io/zeek-zhao
#   TAG        镜像标签，默认 latest
#
# 范围：只格式化各语言目录（<lang>/）下的源码。
#   scripts/、images/、以及各用例里的 run.sh 不在范围内 —— 它们属于基础设施，
#   而动基础设施会让格式化 PR 变成门禁变更，失去「纯排版、可零风险审阅」的意义。
# ==================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REGISTRY="${REGISTRY:-ghcr.io/zeek-zhao}"
TAG="${TAG:-latest}"

MODE="write"
LANGS=""
ALL_LANGS=(cpp go rust shell python java)

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --list)  MODE="list";  shift ;;
    --lang)
      [ "$#" -ge 2 ] || { echo "--lang 缺少参数" >&2; exit 2; }
      LANGS="${2//,/ }"
      shift 2
      ;;
    -h|--help)
      sed -n '2,30p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "未知参数：$1（用 --help 看用法）" >&2
      exit 2
      ;;
  esac
done

# 语言 -> 工具（只用于 --list 与日志，不参与执行）
declare -A TOOL=(
  [cpp]="clang-format 18（LLVM 基线，见 .clang-format）"
  [go]="gofmt（无配置，官方强制）"
  [rust]="rustfmt（见 rustfmt.toml）"
  [shell]="shfmt -i 2 -ci -ln bash"
  [python]="ruff format（见 ruff.toml）"
  [java]="google-java-format 1.22.0 --aosp（4 空格，见 install/java.sh）"
)

# 语言 -> 用来确认「镜像里真的有格式化器」的探针命令
# 少了这一步，旧镜像会让 clang-format / gjf 直接 command not found，
# 而 --check 会把它当成「格式有差异」—— 一个完全错误的判据。
declare -A PROBE=(
  [cpp]="clang-format"
  [go]="gofmt"
  [rust]="rustfmt"
  [shell]="shfmt"
  [python]="ruff"
  [java]="gjf"
)

# 就地改写
declare -A WRITE_CMD=(
  [cpp]='find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -print0 | xargs -0 -r clang-format -i'
  [go]='gofmt -w .'
  [rust]='find . -type f -name "*.rs" -print0 | xargs -0 -r rustfmt --edition 2021'
  [shell]='find . -type f -name "*.sh" -print0 | xargs -0 -r shfmt -w -i 2 -ci -ln bash'
  [python]='ruff format .'
  [java]='find . -type f -name "*.java" -print0 | xargs -0 -r gjf --aosp --replace'
)

# 只检查：有差异时非零退出
declare -A CHECK_CMD=(
  [cpp]='find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -print0 | xargs -0 -r clang-format --dry-run --Werror'
  [go]='out="$(gofmt -l .)"; if [ -n "$out" ]; then printf "%s\n" "$out"; exit 1; fi'
  [rust]='find . -type f -name "*.rs" -print0 | xargs -0 -r rustfmt --check --edition 2021'
  [shell]='find . -type f -name "*.sh" -print0 | xargs -0 -r shfmt -d -i 2 -ci -ln bash'
  [python]='ruff format --check .'
  [java]='find . -type f -name "*.java" -print0 | xargs -0 -r gjf --aosp --dry-run --set-exit-if-changed'
)

if [ "$MODE" = "list" ]; then
  printf '%-8s %s\n' "语言" "格式化工具"
  printf '%-8s %s\n' "----" "---------"
  for l in "${ALL_LANGS[@]}"; do
    printf '%-8s %s\n' "$l" "${TOOL[$l]}"
  done
  exit 0
fi

if [ -z "$LANGS" ]; then
  LANGS="${ALL_LANGS[*]}"
fi

# 语言名必须认识，否则 --lang 打错字会静默「全部跳过」看起来像成功
for l in $LANGS; do
  case " ${ALL_LANGS[*]} " in
    *" $l "*) ;;
    *) echo "未知语言：$l（可选：${ALL_LANGS[*]}）" >&2; exit 2 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "需要 docker：格式化器只装在语言镜像里，宿主没有" >&2
  exit 2
fi

if [ "$MODE" = "check" ]; then
  echo "==> 格式化检查（只读，不改写）"
else
  echo "==> 格式化（就地改写）"
fi
echo "    镜像前缀 ${REGISTRY}，标签 ${TAG}"

failed_langs=()
checked=0

for l in $LANGS; do
  if [ ! -d "$ROOT/$l" ]; then
    printf '  %-8s 跳过（没有 %s/ 目录）\n' "$l" "$l"
    continue
  fi

  image="${REGISTRY}/devbox-${l}:${TAG}"
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    printf '  %-8s 失败：镜像不存在 %s\n' "$l" "$image" >&2
    failed_langs+=("$l")
    continue
  fi

  # 先确认镜像里真的有格式化器。不确认的话，旧镜像会让下面的命令
  # command not found 并以非零退出，--check 模式下会被误报成「格式有差异」。
  if ! docker run --rm "$image" bash -c "command -v ${PROBE[$l]}" >/dev/null 2>&1; then
    printf '  %-8s 失败：镜像 %s 里没有 %s\n' "$l" "$image" "${PROBE[$l]}" >&2
    printf '           这是引入格式化之前的旧镜像，需要重新构建该层\n' >&2
    failed_langs+=("$l")
    continue
  fi

  if [ "$MODE" = "check" ]; then
    cmd="${CHECK_CMD[$l]}"
  else
    cmd="${WRITE_CMD[$l]}"
  fi

  # --user 让容器写出的文件仍归当前用户所有，否则 root 属主的文件
  # 会让后续 git 操作 Permission denied（Windows 上尤其难查）。
  # HOME 指到 /tmp，避免 ruff / java 找不到可写的家目录。
  if docker run --rm \
      --user "$(id -u):$(id -g)" \
      -e HOME=/tmp \
      -v "$ROOT:/work" \
      -w "/work/$l" \
      "$image" bash -c "$cmd"; then
    printf '  %-8s OK   %s\n' "$l" "${TOOL[$l]}"
  else
    printf '  %-8s 有差异（%s）\n' "$l" "${TOOL[$l]}" >&2
    failed_langs+=("$l")
  fi
  checked=$((checked + 1))
done

echo
if [ "${#failed_langs[@]}" -gt 0 ]; then
  if [ "$MODE" = "check" ]; then
    echo "汇总：${#failed_langs[@]} 门语言格式不达标（${failed_langs[*]}）" >&2
    echo "修法：make fmt" >&2
  else
    echo "汇总：${#failed_langs[@]} 门语言格式化失败（${failed_langs[*]}）" >&2
  fi
  exit 1
fi

if [ "$checked" -eq 0 ]; then
  echo "汇总：没有任何语言被处理（检查 --lang 与目录是否存在）" >&2
  exit 2
fi

if [ "$MODE" = "check" ]; then
  echo "汇总：${checked} 门语言格式全部达标"
else
  echo "汇总：${checked} 门语言格式化完成"
fi
