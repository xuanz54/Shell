#!/usr/bin/env bash
# 磁盘使用率检查，超过阈值报警（可用于 cron 巡检）
# 用法: ./disk-usage.sh [阈值百分比]
THRESHOLD="${1:-80}"
EXIT_CODE=0

echo "===== 磁盘使用率检查 $(date '+%F %T') ====="
printf "%-20s %8s %8s %6s %s\n" "文件系统" "容量" "已用" "使用率" "挂载点"

df -hP 2>/dev/null | awk 'NR>1 && !/tmpfs|devtmpfs|overlay|squashfs|loop/ {
    gsub("%","",$5)
    printf "%-20s %8s %8s %5s%% %s\n", $1, $2, $3, $5, $6
}'

echo ""
while read -r usage mount; do
    [ -z "$usage" ] && continue
    if [ "$usage" -ge "$THRESHOLD" ]; then
        echo "[警告] $mount 使用率 ${usage}% 超过阈值 ${THRESHOLD}%"
        EXIT_CODE=1
    fi
done < <(df -P 2>/dev/null | awk 'NR>1 && !/tmpfs|devtmpfs|overlay|squashfs|loop/ {gsub("%","",$5); print $5, $6}')

# 输出最大的 10 个目录（可选，较慢时注释掉）
# echo ""
# echo "----- 当前目录下最大的 10 个目录 -----"
# du -h --max-depth=2 . 2>/dev/null | sort -rh | head -10

exit $EXIT_CODE
