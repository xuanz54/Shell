#!/bin/bash
# macOS 登录审计 - 对应 系统/登录审计.sh
# 使用 last、show、unified log
set -uo pipefail

echo "===== 登录审计 $(date '+%F %T') ====="

echo ""
echo "-- 当前登录用户 --"
who

echo ""
echo "-- 最近 10 条登录记录 --"
last -n 10 2>/dev/null || last | head -10

echo ""
echo "-- 最近 SSH 会话 --"
last | grep -E "ssh|pts" | head -10 || echo "  无 SSH 记录"

echo ""
echo "-- 失败登录尝试（最近 50 条系统日志）--"
# macOS Catalina+ unified log
if log show --last 1d --predicate 'eventMessage CONTAINS "authentication failure" OR eventMessage CONTAINS "Failed password" OR eventMessage CONTAINS "failed auth"' 2>/dev/null | head -50 | grep -q .; then
    log show --last 1d --predicate 'eventMessage CONTAINS "authentication failure" OR eventMessage CONTAINS "Failed password" OR eventMessage CONTAINS "failed auth"' 2>/dev/null | tail -20
else
    # 旧系统
    grep -i "failure\|failed" /var/log/system.log 2>/dev/null | tail -20 || echo "  无失败记录或日志不可读"
fi

echo ""
echo "-- 安全审计（需要 full disk access 时可能为空）--"
log show --last 1h --predicate 'subsystem == "com.apple.System.security"' --info 2>/dev/null | grep -i "auth" | tail -10 || echo "  无数据（终端可能需要完全磁盘访问权限）"
