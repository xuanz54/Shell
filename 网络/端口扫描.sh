#!/usr/bin/env bash
# 端口扫描器（纯 bash 实现，扫描常见端口或指定范围）
# 用法: ./port-scanner.sh <host> [start-port end-port]
set -uo pipefail

HOST="${1:-}"
START="${2:-1}"
END="${3:-1024}"

[ -z "$HOST" ] && { echo "用法: $0 <host> [start end]"; echo "示例: $0 192.168.1.10 1 65535"; exit 1; }

COMMON_PORTS=(21 22 23 25 53 80 110 143 443 445 993 995 3306 3389 5432 6379 8080 8443 9090 27017)

echo "===== 端口扫描 $HOST ($START-$END) $(date '+%F %T') ====="
OPEN=0

scan_port() {
    if timeout 1 bash -c "echo >/dev/tcp/$HOST/$1" 2>/dev/null; then
        echo "[开放] $HOST:$1"
    fi
}

export -f scan_port
export HOST

if [ "$START" -eq 1 ] && [ "$END" -eq 1024 ]; then
    # 快速模式：只扫常见端口 + 1-1024 并行
    for port in "${COMMON_PORTS[@]}"; do
        scan_port "$port" &
    done
    for port in $(seq "$START" "$END"); do
        scan_port "$port" &
        # 控制并发
        while [ "$(jobs -rp | wc -l)" -ge 200 ]; do wait -n; done
    done
else
    for port in $(seq "$START" "$END"); do
        scan_port "$port" &
        while [ "$(jobs -rp | wc -l)" -ge 200 ]; do wait -n; done
    done
fi
wait

echo "扫描完成"
