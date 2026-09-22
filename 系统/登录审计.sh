#!/usr/bin/env bash
# 登录安全审计：失败登录、当前登录、最近登录记录
set -euo pipefail

echo "===== 登录审计 $(date '+%F %T') ====="

echo ""
echo "----- 当前登录用户 -----"
who 2>/dev/null || w

echo ""
echo "----- 最近 10 条登录记录 -----"
last -n 10 2>/dev/null || last | head -10

echo ""
echo "----- 失败登录尝试 Top 10 来源 IP -----"
if [ -f /var/log/auth.log ]; then
    grep "Failed password" /var/log/auth.log 2>/dev/null \
        | grep -oP 'from \K[0-9.]+' \
        | sort | uniq -c | sort -rn | head -10
elif [ -f /var/log/secure ]; then
    grep "Failed password" /var/log/secure 2>/dev/null \
        | grep -oP 'from \K[0-9.]+' \
        | sort | uniq -c | sort -rn | head -10
else
    journalctl -u ssh --since "7 days ago" 2>/dev/null \
        | grep -i "failed" | grep -oP 'from \K[0-9.]+' \
        | sort | uniq -c | sort -rn | head -10 || echo "无可用日志"
fi

echo ""
echo "----- 失败登录次数（按用户名）-----"
if [ -f /var/log/auth.log ]; then
    grep "Failed password" /var/log/auth.log 2>/dev/null \
        | grep -oP 'for (invalid user )?\K\S+' | sort | uniq -c | sort -rn | head -10
elif [ -f /var/log/secure ]; then
    grep "Failed password" /var/log/secure 2>/dev/null \
        | grep -oP 'for (invalid user )?\K\S+' | sort | uniq -c | sort -rn | head -10
else
    echo "无可用日志"
fi
