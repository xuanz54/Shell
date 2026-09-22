#!/usr/bin/env bash
# 公网 IP 与地理位置查询
set -uo pipefail

echo "===== 网络出口信息 $(date '+%F %T') ====="

echo ""
echo "-- 公网 IP --"
IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "")
echo "${IP:-获取失败}"

if [ -n "$IP" ]; then
    echo ""
    echo "-- IP 详情 --"
    curl -s --max-time 5 "https://ipinfo.io/$IP/json" 2>/dev/null | \
        grep -E '"(ip|hostname|city|region|country|org|loc)"' | tr -d '",' | sed 's/:/  /'
fi

echo ""
echo "-- 本地 DNS --"
grep -E "^(nameserver|search)" /etc/resolv.conf 2>/dev/null || echo "无法读取 /etc/resolv.conf"

echo ""
echo "-- 本地接口 --"
ip -br addr show 2>/dev/null || ifconfig 2>/dev/null | grep -E "inet |^[a-z]"
