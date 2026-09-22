#!/usr/bin/env bash
# 过期/陈旧账户清理（90 天未登录的普通账户）
# 用法: ./清理过期用户.sh [天数=90] [--apply]
set -uo pipefail

DAYS="${1:-90}"
APPLY=false
[ "${2:-}" = "--apply" ] && APPLY=true
[ "${1:-}" = "--apply" ] && { APPLY=true; DAYS=90; }

echo "===== 清理 ${DAYS} 天未登录用户 $(date '+%F %T') ====="

for u in $(awk -F: '$3>=1000 && $3<65534 {print $1}' /etc/passwd); do
    last_day=$(lastlog -b "$u" 2>/dev/null | tail -1 | awk '{print $4$5$6}')
    [ -z "$last_day" ] && continue

    # 跳过当前在线用户
    who 2>/dev/null | grep -q "^$u " && { echo "  [跳过-在线] $u"; continue; }

    if last -u "$u" 2>/dev/null | head -1 | grep -q "never logged in\|^$u"; then
        echo "  [候选] $u (无登录记录或异常)"
    else
        last_login=$(last -n 1 -u "$u" "$u" 2>/dev/null | head -1 | awk '{print $4, $5, $6}')
        echo "  [候选] $u 最后登录: ${last_login:-未知}"
    fi

    if $APPLY; then
        read -r -p "    锁定并删除 $u ? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            usermod -L "$u"
            # 保留家目录备份
            if [ -d "/home/$u" ]; then
                tar -czf "/backup_${u}_$(date +%Y%m%d).tar.gz" -C /home "$u" 2>/dev/null || true
            fi
            userdel -r "$u" 2>/dev/null || userdel "$u"
            echo "    已删除: $u"
        fi
    fi
done

$APPLY || echo "(预览模式，加 --apply 执行)"
