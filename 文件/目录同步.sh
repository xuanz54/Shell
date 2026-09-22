#!/usr/bin/env bash
# 目录同步（rsync 封装，支持镜像/增量/带宽限制）
# 用法: ./sync-folder.sh <源> <目标> [--delete] [--bwlimit KB/s] [--dry-run]
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "用法: $0 <源> <目标> [--delete] [--bwlimit N] [--dry-run]"
    echo "示例: $0 /data/ /backup/data/ --delete --dry-run"
    exit 1
fi

SRC="$1"; DST="$2"; shift 2

command -v rsync >/dev/null 2>&1 || { echo "错误: 未安装 rsync"; exit 1; }

OPTS=(-a -v --progress --human-readable)
for arg in "$@"; do
    case "$arg" in
        --delete)   OPTS+=(--delete) ;;
        --dry-run)  OPTS+=(--dry-run) ;;
        --bwlimit=*) OPTS+=(--bwlimit="${arg#--bwlimit=}") ;;
        --bwlimit)  ;; # 处理 value 在下一参数的情况，简化处理见下
        *) if [ "$prev" = "--bwlimit" ]; then OPTS+=(--bwlimit="$arg"); fi ;;
    esac
    prev="$arg"
done

echo "===== 目录同步 $(date '+%F %T') ====="
echo "源: $SRC"
echo "目标: $DST"
echo "选项: ${OPTS[*]}"
echo ""

rsync "${OPTS[@]}" "$SRC" "$DST"
echo ""
echo "同步完成"
