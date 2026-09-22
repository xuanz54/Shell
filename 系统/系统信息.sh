#!/usr/bin/env bash
# 系统信息一键查看
set -euo pipefail

echo "========== 系统信息 =========="
echo "主机名:   $(hostname)"
echo "系统:     $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -s)"
echo "内核:     $(uname -r)"
echo "运行时间: $(uptime -p 2>/dev/null || uptime)"
echo ""
echo "========== CPU =========="
grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //' || sysctl -n machdep.cpu.brand_string 2>/dev/null || true
echo "核心数:   $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo unknown)"
echo "负载:     $(cat /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')"
echo ""
echo "========== 内存 =========="
free -h 2>/dev/null || vm_stat 2>/dev/null || true
echo ""
echo "========== 磁盘 =========="
df -hT 2>/dev/null | grep -Ev "tmpfs|overlay|udev" || df -h
echo ""
echo "========== 网络 =========="
ip -br addr 2>/dev/null || ifconfig 2>/dev/null || true
