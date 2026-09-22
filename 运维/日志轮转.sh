#!/usr/bin/env bash
# 日志轮转压缩：压缩 N 天前的日志，删除 M 天前的 .gz
# 用法: ./日志轮转.sh [日志目录, 默认 /var/log] [压缩天数=7] [删除天数=30]
set -euo pipefail

DIR="${1:-/var/log}"
COMPRESS_DAYS="${2:-7}"
DELETE_DAYS="${3:-30}"

[ -d "$DIR" ] || { echo "目录不存在: $DIR"; exit 1; }

echo "===== 日志轮转: $DIR (压缩>${COMPRESS_DAYS}天, 删除>${DELETE_DAYS}天) ====="

# 压缩 7 天前修改的 .log（不含已压缩）
find "$DIR" -type f -name "*.log" -mtime +"$COMPRESS_DAYS" 2>/dev/null | while read -r f; do
    if gzip -9 "$f" 2>/dev/null; then
        echo "已压缩: $f.gz"
    else
        echo "压缩失败: $f"
    fi
done

# 删除过期 .gz
find "$DIR" -type f \( -name "*.gz" -o -name "*.bz2" -o -name "*.xz" \) -mtime +"$DELETE_DAYS" -print -delete 2>/dev/null \
    | sed 's/^/已删除: /'

# 删除超过 90 天的轮转文件
find "$DIR" -type f \( -name "*.log.[0-9]*" -o -name "*.[0-9].gz" \) -mtime +90 -delete 2>/dev/null || true

echo "完成。当前 $DIR 占用:"
du -sh "$DIR" 2>/dev/null
