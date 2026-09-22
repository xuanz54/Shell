#!/usr/bin/env bash
# 目录定时备份（tar.gz + 保留最近 N 份）
# 用法: ./backup-dir.sh <源目录> <备份目录> [保留份数, 默认 7]
set -euo pipefail

SRC="${1:-}"
DEST="${2:-}"
KEEP="${3:-7}"

[ -n "$SRC" ] && [ -n "$DEST" ] || { echo "用法: $0 <源目录> <备份目录> [保留份数]"; exit 1; }
[ -d "$SRC" ] || { echo "源目录不存在: $SRC"; exit 1; }

mkdir -p "$DEST"
BASE=$(basename "$SRC")
STAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$DEST/${BASE}_${STAMP}.tar.gz"
LOG="$DEST/backup.log"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

log "开始备份: $SRC -> $ARCHIVE"
tar -czf "$ARCHIVE.tmp" -C "$(dirname "$SRC")" "$BASE"
mv "$ARCHIVE.tmp" "$ARCHIVE"
SIZE=$(ls -lh "$ARCHIVE" | awk '{print $5}')
log "备份完成: $ARCHIVE ($SIZE)"

# 轮转：只保留最近 N 份
cd "$DEST"
ls -1t ${BASE}_*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
    rm -f -- "$old"
    log "删除旧备份: $old"
done

log "当前备份列表:"
ls -1t ${BASE}_*.tar.gz 2>/dev/null | head -"$KEEP" | sed "s/^/  /" | tee -a "$LOG"
