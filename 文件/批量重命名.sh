#!/usr/bin/env bash
# 批量重命名文件（支持前缀、替换、序号）
# 用法:
#   ./batch-rename.sh -d 目录 -p 新前缀        # 加前缀
#   ./batch-rename.sh -d 目录 -r "旧:新"        # 替换字符串
#   ./batch-rename.sh -d 目录 -s "img"          # 序号命名 img_001.jpg
set -euo pipefail

DIR="."
MODE=""
ARG=""
DRY_RUN=true

while [ $# -gt 0 ]; do
    case "$1" in
        -d) DIR="$2"; shift 2 ;;
        -p) MODE="prefix"; ARG="$2"; shift 2 ;;
        -r) MODE="replace"; ARG="$2"; shift 2 ;;
        -s) MODE="seq"; ARG="$2"; shift 2 ;;
        --apply) DRY_RUN=false; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

[ -d "$DIR" ] || { echo "目录不存在: $DIR"; exit 1; }
[ -n "$MODE" ] || { echo "用法见脚本头部注释"; exit 1; }

rename_file() {
    local src="$1" dst="$2"
    [ "$src" = "$dst" ] && return 0
    if $DRY_RUN; then
        echo "[预览] $src  ->  $dst"
    else
        if [ -e "$dst" ]; then
            echo "[跳过] 目标已存在: $dst"
        else
            mv -- "$src" "$dst"
            echo "[重命名] $src  ->  $dst"
        fi
    fi
}

cd "$DIR"
i=0
shopt -s nullglob
for f in *; do
    [ -f "$f" ] || continue
    i=$((i + 1))
    name="${f%.*}"
    ext=""
    [ "$f" != "$name" ] && ext=".${f##*.}"

    case "$MODE" in
        prefix) new="${ARG}_${f}" ;;
        replace)
            old="${ARG%%:*}"; new_arg="${ARG#*:}"
            new="${f//$old/$new_arg}"
            ;;
        seq) new="$(printf '%s_%03d%s' "$ARG" "$i" "$ext")" ;;
    esac
    rename_file "$f" "$new"
done

echo ""
$DRY_RUN && echo "以上为预览，确认无误后加 --apply 执行"
