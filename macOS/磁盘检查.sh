#!/bin/bash
# macOS 磁盘使用率检查 - 对应 系统/磁盘检查.sh
# 用法: ./磁盘检查.sh [阈值百分比]
set -uo pipefail

THRESHOLD="${1:-80}"
EXIT_CODE=0

echo "===== 磁盘使用率检查 $(date '+%F %T') (阈值 ${THRESHOLD}%) ====="
printf "%-20s %8s %8s %6s %s\n" "设备" "容量" "已用" "使用率" "挂载点"

df -hP | awk 'NR>1 && !/dev\/disk[0-9]s[0-9]s[0-9]|map |\/System\/Volumes\/VM/ {
    # macOS 有一些系统卷，关注主要卷
    if ($6 ~ /^\/dev\/disk/ || $6 == "/") {
        pct=$5; gsub("%","",pct)
        printf "%-20s %8s %8s %5s%% %s\n", $1, $2, $3, pct, $6
    }
}'

echo ""
while read -r usage mount; do
    [ -z "$usage" ] && continue
    if [ "$usage" -ge "$THRESHOLD" ]; then
        echo "[警告] $mount 使用率 ${usage}% 超过阈值 ${THRESHOLD}%"
        EXIT_CODE=1
    fi
done < <(df -P 2>/dev/null | awk 'NR>1 {pct=$5; gsub("%","",pct); if ($6=="/" || $6 ~ /\/System\/Volumes\/Data/) print pct, $6}')

echo ""
echo "----- 当前目录占用 -----"
du -sh . 2>/dev/null

exit $EXIT_CODE
