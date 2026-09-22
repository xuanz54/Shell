#!/usr/bin/env bash
# MySQL/Mariadb 数据库备份
# 用法: ./backup-mysql.sh
#   环境变量: DB_HOST DB_PORT DB_USER DB_PASS DB_NAME BACKUP_DIR KEEP
set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-}"
DB_NAME="${DB_NAME:-}"
BACKUP_DIR="${BACKUP_DIR:-/backup/mysql}"
KEEP="${KEEP:-7}"
STAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"
AUTH=(-h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER")
[ -n "$DB_PASS" ] && AUTH+=(-p"$DB_PASS")

echo "[$(date '+%F %T')] 开始 MySQL 备份 -> $BACKUP_DIR"

if [ -n "$DB_NAME" ]; then
    OUT="$BACKUP_DIR/${DB_NAME}_${STAMP}.sql.gz"
    mysqldump "${AUTH[@]}" --single-transaction --routines --triggers "$DB_NAME" | gzip > "$OUT"
    echo "已备份库: $DB_NAME"
else
    OUT="$BACKUP_DIR/all_${STAMP}.sql.gz"
    mysqldump "${AUTH[@]}" --single-transaction --routines --triggers --all-databases | gzip > "$OUT"
    echo "已备份全部库"
fi

ls -lh "$OUT"

# 轮转
ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "[$(date '+%F %T')] 备份完成，保留最近 $KEEP 份"
