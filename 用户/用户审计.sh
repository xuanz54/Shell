#!/usr/bin/env bash
# 用户与权限审计
set -euo pipefail

echo "===== 用户权限审计 $(date '+%F %T') ====="

echo ""
echo "-- 可登录用户 (shell 非 nologin) --"
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {printf "  %-15s uid=%-6s home=%s shell=%s\n", $1,$3,$6,$7}' /etc/passwd

echo ""
echo "-- 空密码用户 --"
if [ -r /etc/shadow ]; then
    awk -F: '($2 == "" || $2 == "!") {print "  " $1}' /etc/shadow
    echo "  (以上若无输出则无空密码用户)"
else
    echo "  无法读取 /etc/shadow（需要 root）"
fi

echo ""
echo "-- sudo/wheel 组成员 --"
getent group sudo wheel 2>/dev/null | sed 's/^/  /' || echo "  无"

echo ""
echo "-- UID=0 的非 root 账户 --"
awk -F: '$3 == 0 && $1 != "root" {print "  " $1}' /etc/passwd || true

echo ""
echo "-- 最近修改过的用户文件 --"
find /home -maxdepth 3 -name ".ssh" -o -name ".bashrc" 2>/dev/null | head -10 | sed 's/^/  /'

echo ""
echo "-- 账户状态 --"
for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
    status=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
    printf "  %-15s %s\n" "$u" "${status:-未知}"
done
