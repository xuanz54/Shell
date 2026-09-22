#!/usr/bin/env bash
# 数据库定时备份 + 异地上传（mysqldump + rclone/scp）
# 用法: 环境变量配置后作为 cron 任务执行
set -euo pipefail

DB_NAME="${DB_NAME:-all}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-}"
BACKUP_DIR="${BACKUP_DIR:-/backup/db}"
KEEP="${KEEP:-14}"
REMOTE="${REMOTE:-}"          # 如: rclone:path/to/ 或 user@host:/backup/
STAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"
OUT="$BACKUP_DIR/${DB_NAME}_${STAMP}.sql.gz"

AUTH=(-u "$DB_USER")
[ -n "$DB_PASS" ] && AUTH+=(-p"$DB_PASS")

echo "[$(date '+%F %T')] 备份数据库 $DB_NAME"

if [ "$DB_NAME" = "all" ]; then
    mysqldump "${AUTH[@]}" --single-transaction --all-databases | gzip > "$OUT"
else
    mysqldump "${AUTH[@]}" --single-transaction "$DB_NAME" | gzip > "$OUT"
fi

ls -lh "$OUT"

# 异地上传
if [ -n "$REMOTE" ]; then
    case "$REMOTE" in
        rclone:*)
            rclone copyto "$OUT" "${REMOTE#rclone:}/$(basename "$OUT")" && echo "已上传 rclone" ;;
        *:*)
            scp -q "$OUT" "$REMOTE/" && echo "已上传 scp: $REMOTE" ;;
        *)
            echo "无法识别的 REMOTE: $REMOTE" ;;
    esac
fi

# 本地轮转
ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "[$(date '+%F %T')] 完成"
