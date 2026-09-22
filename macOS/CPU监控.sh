#!/bin/bash
# macOS CPU 监控 - 对应 系统/CPU监控.sh
# 用法: ./CPU监控.sh [间隔秒] [次数, 0=无限]
set -uo pipefail

INTERVAL="${1:-2}"
COUNT="${2:-0}"

command -v top >/dev/null 2>&1 || { echo "需要 top 命令"; exit 1; }

i=0
while true; do
    clear
    echo "===== CPU 监控 $(date '+%F %T') ====="

    # macOS top 批处理模式取一次快照
    top -l 1 -n 10 -o cpu -stats pid,cpu,mem,command 2>/dev/null | tail -n +12

    i=$((i + 1))
    [ "$COUNT" -gt 0 ] && [ "$i" -ge "$COUNT" ] && break
    sleep "$INTERVAL"
done
