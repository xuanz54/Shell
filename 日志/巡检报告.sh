#!/usr/bin/env bash
# 磁盘/服务定时巡检报告（适合 cron 每日执行）
# 用法: ./巡检报告.sh [接收邮箱]
set -uo pipefail

MAIL_TO="${1:-}"
REPORT="/tmp/巡检报告_$(date +%Y%m%d).html"
HOST=$(hostname)

{
    echo "<h2>服务器巡检报告 - $HOST - $(date '+%F %T')</h2>"

    echo "<h3>系统负载</h3><pre>"
    uptime
    echo "</pre>"

    echo "<h3>磁盘使用</h3><pre>"
    df -hT | grep -Ev "tmpfs|overlay|devtmpfs"
    echo "</pre>"

    echo "<h3>内存</h3><pre>"
    free -h
    echo "</pre>"

    echo "<h3>CPU Top 5</h3><pre>"
    ps -eo pcpu,pmem,rss,comm --sort=-pcpu | head -6
    echo "</pre>"

    echo "<h3>异常服务</h3><pre>"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --failed --no-legend 2>/dev/null || echo "无"
    else
        echo "非 systemd 系统"
    fi
    echo "</pre>"

    echo "<h3>最近登录失败</h3><pre>"
    { grep "Failed password" /var/log/auth.log 2>/dev/null || grep "Failed password" /var/log/secure 2>/dev/null || echo "无"; } | tail -5
    echo "</pre>"

    # 磁盘超 85% 标红
    echo "<h3>磁盘告警</h3><pre>"
    df -P | awk 'NR>1 && !/tmpfs|overlay/ {gsub("%","",$5); if ($5>85) print "警告: "$6" 使用率 "$5"%"}'
    echo "</pre>"
} > "$REPORT"

echo "报告已生成: $REPORT"
cat "$REPORT" | sed 's/<[^>]*>//g'

if [ -n "$MAIL_TO" ] && command -v mail >/dev/null 2>&1; then
    mail -s "[$HOST] 巡检报告 $(date +%F)" "$MAIL_TO" < "$REPORT" && echo "已发送至 $MAIL_TO"
fi
