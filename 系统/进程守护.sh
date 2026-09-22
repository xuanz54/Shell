#!/usr/bin/env bash
# 进程守护：进程退出后自动重启（简单守护）
# 用法: ./process-watch.sh <命令...>
# 示例: ./process-watch.sh -- /usr/bin/myapp --config /etc/app.conf
set -uo pipefail

if [ "${1:-}" = "--" ]; then shift; fi
if [ $# -eq 0 ]; then
    echo "用法: $0 -- <命令...>"
    echo "示例: $0 -- nginx -g 'daemon off;'"
    exit 1
fi

MAX_RESTARTS=100
INTERVAL=3
restarts=0

trap 'echo "收到退出信号，停止守护"; exit 0' INT TERM

echo "===== 进程守护启动: $* ====="

while [ "$restarts" -lt "$MAX_RESTARTS" ]; do
    echo "[$(date '+%F %T')] 启动: $*"
    "$@" &
    PID=$!
    wait "$PID"
    CODE=$?
    restarts=$((restarts + 1))
    echo "[$(date '+%F %T')] 进程退出，code=$CODE，第 ${restarts} 次重启（${INTERVAL}s 后）"
    sleep "$INTERVAL"
done

echo "[警告] 已达最大重启次数 $MAX_RESTARTS，退出"
exit 1
