#!/usr/bin/env bash
# Rsync 远程备份（增量，适合整机目录同步）
# 用法: ./backup-remote.sh <源目录> <user@host:目标路径> [--delete]
set -euo pipefail

SRC="${1:-}"
DEST="${2:-}"
shift 2 2>/dev/null || true

[ -n "$SRC" ] && [ -n "$DEST" ] || { echo "用法: $0 <源> <user@host:path> [--delete]"; exit 1; }
[ -d "$SRC" ] || { echo "源不存在: $SRC"; exit 1; }
command -v rsync >/dev/null || { echo "未安装 rsync"; exit 1; }

LOG="/var/log/backup-remote_$(date +%Y%m%d).log"
OPTS=(-a -z -v --progress --stats)

for arg in "$@"; do
    [ "$arg" = "--delete" ] && OPTS+=(--delete)
done

echo "[$(date '+%F %T')] rsync $SRC -> $DEST" | tee -a "$LOG"
rsync "${OPTS[@]}" "$SRC" "$DEST" 2>&1 | tee -a "$LOG"
echo "[$(date '+%F %T')] 完成" | tee -a "$LOG"
