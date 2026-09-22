#!/usr/bin/env bash
# PostgreSQL 数据库备份
# 用法: 环境变量 PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE BACKUP_DIR KEEP
set -euo pipefail

PGDATABASE="${PGDATABASE:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-/backup/postgres}"
KEEP="${KEEP:-7}"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$BACKUP_DIR/${PGDATABASE}_${STAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "[$(date '+%F %T')] 开始 PostgreSQL 备份: $PGDATABASE"

pg_dump -Fc "$PGDATABASE" 2>/dev/null | gzip > "$OUT" \
    || pg_dump "$PGDATABASE" | gzip > "$OUT"

ls -lh "$OUT"

ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "[$(date '+%F %T')] 备份完成，保留最近 $KEEP 份"
