#!/usr/bin/env bash
# 查找大文件
# 用法: ./查找大文件.sh [目录] [大小阈值, 默认 +100M] [返回条数, 默认 20]
set -uo pipefail

DIR="${1:-.}"
SIZE="${2:-+100M}"
LIMIT="${3:-20}"

echo "===== 大文件查找: $DIR (阈值 $SIZE) $(date '+%F %T') ====="
find "$DIR" -type f -size "$SIZE" -printf '%s %p\n' 2>/dev/null \
    | sort -rn \
    | head -"$LIMIT" \
    | awk '{
        s=$1; $1=""
        sub(/^ /,"")
        if (s>=1073741824) h=s/1073741824" GB"
        else if (s>=1048576) h=s/1048576" MB"
        else if (s>=1024) h=s/1024" KB"
        else h=s" B"
        printf "%10s  %s\n", h, $0
    }'

echo ""
echo "----- 按目录汇总 Top 20 -----"
du -h --max-depth=3 "$DIR" 2>/dev/null | sort -rh | head -20
