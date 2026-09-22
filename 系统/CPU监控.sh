#!/usr/bin/env bash
# CPU 占用 Top 进程监控（持续输出）
# 用法: ./cpu-monitor.sh [间隔秒数] [次数, 0=无限]
INTERVAL="${1:-2}"
COUNT="${2:-0}"
WIDTH="${COLUMNS:-100}"

trap 'echo; exit 0' INT

i=0
while true; do
    clear
    echo "===== CPU 监控 $(date '+%F %T') ====="
    echo "总 CPU: $(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2+$4"% used"}' || grep cpu /proc/stat | awk '{printf "%.1f%% used\n", 100-($5*100)/($2+$3+$4+$5)}')"
    ps -eo pid,ppid,user,pcpu,pmem,etime,comm --sort=-pcpu 2>/dev/null | head -11 | cut -c1-"$WIDTH"
    i=$((i + 1))
    [ "$COUNT" -gt 0 ] && [ "$i" -ge "$COUNT" ] && break
    sleep "$INTERVAL"
done
