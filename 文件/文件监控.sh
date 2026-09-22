#!/usr/bin/env bash
# 文件变化监控（简化版 inotifywait）
# 用法: ./watch-files.sh <目录> [pattern]
set -uo pipefail

DIR="${1:-.}"
PATTERN="${2:-}"

[ -d "$DIR" ] || { echo "目录不存在: $DIR"; exit 1; }

echo "===== 监控 $DIR $(date '+%F %T') ====="
echo "事件: 创建/修改/删除/重命名 | Ctrl+C 退出"

if command -v inotifywait >/dev/null 2>&1; then
    inotifywait -m -r -e create,modify,delete,move --format '%T %e %w%f' --timefmt '%F %T' \
        ${PATTERN:+--include "$PATTERN"} "$DIR"
else
    # 降级方案：轮询快照对比
    echo "[提示] 未安装 inotify-tools，使用 2 秒轮询模式"
    prev=""
    while sleep 2; do
        cur=$(find "$DIR" -type f -newermt "-3 seconds" 2>/dev/null | sort)
        if [ "$cur" != "$prev" ] && [ -n "$prev" ]; then
            comm -13 <(echo "$prev") <(echo "$cur") | while read -r f; do
                echo "$(date '+%F %T') [变化] $f"
            done
        fi
        prev="$cur"
    done
fi
