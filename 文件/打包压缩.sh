#!/usr/bin/env bash
# 文件/目录打包压缩（tar.gz / tar.bz2 / zip）
# 用法: ./archive.sh <源文件/目录> [格式: gz|bz2|zip, 默认 gz]
set -euo pipefail

SRC="${1:-}"
FMT="${2:-gz}"

[ -z "$SRC" ] && { echo "用法: $0 <源> [gz|bz2|zip]"; exit 1; }
[ -e "$SRC" ] || { echo "不存在: $SRC"; exit 1; }

BASE="${SRC%/}"
BASE="${BASE##*/}"
STAMP=$(date +%Y%m%d_%H%M%S)

case "$FMT" in
    gz)
        OUT="${BASE}_${STAMP}.tar.gz"
        echo "打包 -> $OUT"
        tar -czf "$OUT" "$BASE"
        ;;
    bz2)
        OUT="${BASE}_${STAMP}.tar.bz2"
        echo "打包 -> $OUT"
        tar -cjf "$OUT" "$BASE"
        ;;
    zip)
        OUT="${BASE}_${STAMP}.zip"
        echo "打包 -> $OUT"
        command -v zip >/dev/null || { echo "未安装 zip"; exit 1; }
        zip -r "$OUT" "$BASE"
        ;;
    *)
        echo "不支持的格式: $FMT"; exit 1 ;;
esac

ls -lh "$OUT"
echo "完成: $OUT"
