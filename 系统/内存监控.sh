#!/usr/bin/env bash
# 内存占用监控：显示内存概览与占内存最多的进程
# 用法: ./memory-monitor.sh [阈值百分比]
THRESHOLD="${1:-80}"

echo "===== 内存使用 $(date '+%F %T') ====="
free -h 2>/dev/null || vm_stat

USED_PCT=$(free -m 2>/dev/null | awk '/Mem:/{printf "%.0f", $3/$2*100}')
echo ""
echo "内存占用率: ${USED_PCT:-unknown}% (阈值 ${THRESHOLD}%)"
echo ""
echo "----- 内存占用 Top 10 -----"
ps -eo pid,user,rss,pmem,comm --sort=-rss 2>/dev/null | head -11 | awk 'NR==1{print; next} {$3=sprintf("%.1fMB", $3/1024); print}'

if [ -n "${USED_PCT:-}" ] && [ "$USED_PCT" -ge "$THRESHOLD" ]; then
    echo ""
    echo "[警告] 内存占用超过阈值 ${THRESHOLD}%!"
    exit 1
fi
