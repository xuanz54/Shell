#!/usr/bin/env bash
# 网络带宽/流量监控（读取 /proc/net/dev，无需额外工具）
# 用法: ./bandwidth-monitor.sh [网卡名, 默认第一个非lo] [间隔秒]
set -uo pipefail

IFACE="${1:-}"
INTERVAL="${2:-2}"

if [ -z "$IFACE" ]; then
    IFACE=$(ls /sys/class/net 2>/dev/null | grep -v "^lo$" | head -1)
fi
[ -z "$IFACE" ] && { echo "未找到网卡"; exit 1; }

read_bytes() {
    awk -v iface="$1" '$1 == iface":" {print $2, $10}' /proc/net/dev
}

echo "===== 带宽监控: $IFACE (间隔 ${INTERVAL}s, Ctrl+C 退出) ====="
printf "%-20s %12s %12s\n" "时间" "接收速率" "发送速率"

read -r RX1 TX1 < <(read_bytes "$IFACE")

while sleep "$INTERVAL"; do
    read -r RX2 TX2 < <(read_bytes "$IFACE")
    DRX=$((RX2 - RX1))
    DTX=$((TX2 - TX1))
    RX1=$RX2; TX1=$TX2

    fmt() {
        awk -v b="$1" -v t="$INTERVAL" 'BEGIN{
            r=b/t
            if (r>1073741824) printf "%.2f GB/s", r/1073741824
            else if (r>1048576) printf "%.2f MB/s", r/1048576
            else if (r>1024) printf "%.2f KB/s", r/1024
            else printf "%.0f B/s", r
        }'
    }
    printf "%-20s %12s %12s\n" "$(date '+%F %T')" "$(fmt "$DRX")" "$(fmt "$DTX")"
done
