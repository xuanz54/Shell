#!/usr/bin/env bash
# 端口连通性检测
# 用法: ./port-check.sh <host> <port> [port2 port3 ...]
set -uo pipefail

HOST="${1:-}"
shift || true
PORTS=("$@")

if [ -z "$HOST" ] || [ ${#PORTS[@]} -eq 0 ]; then
    echo "用法: $0 <host> <port> [port2 ...]"
    echo "示例: $0 192.168.1.1 22 80 443"
    exit 1
fi

echo "===== 端口检测 $HOST $(date '+%F %T') ====="
FAILED=0

for port in "${PORTS[@]}"; do
    if timeout 3 bash -c "echo >/dev/tcp/$HOST/$port" 2>/dev/null; then
        printf "  [开放] %s:%s\n" "$HOST" "$port"
    else
        printf "  [关闭/过滤] %s:%s\n" "$HOST" "$port"
        FAILED=$((FAILED + 1))
    fi
done

exit $([ "$FAILED" -gt 0 ] && echo 1 || echo 0)
