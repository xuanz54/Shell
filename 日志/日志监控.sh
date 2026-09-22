#!/usr/bin/env bash
# 日志关键字实时监控（tail -f + 高亮 + 计数）
# 用法: ./日志监控.sh <日志文件> <关键字...>
set -uo pipefail

LOG="${1:-}"
shift || true
[ -n "$LOG" ] && [ $# -gt 0 ] || { echo "用法: $0 <日志文件> <关键字...>"; exit 1; }
[ -f "$LOG" ] || { echo "文件不存在: $LOG"; exit 1; }

PATTERN=$(IFS='|'; echo "$*")
COUNT_FILE=$(mktemp)
echo 0 > "$COUNT_FILE"
trap 'rm -f "$COUNT_FILE"' EXIT

echo "===== 监控 $LOG | 关键字: $* ====="
echo "按 Ctrl+C 退出"

tail -n 0 -F "$LOG" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -qE "$PATTERN"; then
        c=$(($(cat "$COUNT_FILE") + 1))
        echo "$c" > "$COUNT_FILE"
        printf '\033[1;31m[%s] [#%s]\033[0m %s\n' "$(date '+%T')" "$c" "$line"
        # 可扩展：此处调用告警函数
    fi
done
