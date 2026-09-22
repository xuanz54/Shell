#!/usr/bin/env bash
# 局域网主机发现（ping 扫描）
# 用法: ./lan-scan.sh [网段, 默认当前网段]
# 示例: ./lan-scan.sh 192.168.1
set -uo pipefail

if [ $# -ge 1 ]; then
    SUBNET="$1"
else
    SUBNET=$(ip route 2>/dev/null | awk '/src/ && /scope/ {print $1; exit}' | cut -d/ -f1 | sed 's/\.[0-9]*$//')
    [ -z "$SUBNET" ] && SUBNET=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet )[0-9.]+' | grep -v '^127\.' | head -1 | sed 's/\.[0-9]*$//')
fi

[ -z "$SUBNET" ] && { echo "无法识别网段，请手动指定: $0 192.168.1"; exit 1; }

echo "===== 扫描 ${SUBNET}.0/24 $(date '+%F %T') ====="

scan_host() {
    ip="$1"
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        mac=$(arp -n "$ip" 2>/dev/null | awk '/[0-9a-f]{2}:{6}/{print $4; exit}')
        name=$(getent hosts "$ip" 2>/dev/null | awk '{print $2}' || true)
        echo "$ip  ${mac:--}  ${name:-}"
    fi
}
export -f scan_host

for i in $(seq 1 254); do
    scan_host "${SUBNET}.$i" &
done
wait | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n
echo "扫描完成"
