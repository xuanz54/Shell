#!/usr/bin/env bash
# 备份恢复（解包 tar.gz 备份）
# 用法: ./restore.sh <备份文件.tar.gz> [恢复到目录]
set -euo pipefail

ARCHIVE="${1:-}"
DEST="${2:-.}"

[ -n "$ARCHIVE" ] || { echo "用法: $0 <备份.tar.gz> [目标目录]"; exit 1; }
[ -f "$ARCHIVE" ] || { echo "文件不存在: $ARCHIVE"; exit 1; }

echo "===== 备份恢复 ====="
echo "档案: $ARCHIVE"
echo "目标: $DEST"
echo ""

echo "-- 档案内容预览 --"
tar -tzf "$ARCHIVE" | head -20
echo "..."

read -r -p "确认恢复到 $DEST ? [y/N] " ans
[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "已取消"; exit 0; }

mkdir -p "$DEST"
tar -xzf "$ARCHIVE" -C "$DEST"
echo ""
echo "恢复完成: $DEST"
ls -la "$DEST" | head -20
