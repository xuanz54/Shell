#!/usr/bin/env bash
# SSL 证书过期检查（支持多域名）
# 用法: ./SSL证书检查.sh example.com:443 other.com [天数阈值=30]
set -uo pipefail

THRESHOLD=30
TARGETS=()

for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        THRESHOLD="$arg"
    else
        TARGETS+=("$arg")
    fi
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "用法: $0 <域名[:端口]> [域名2 ...] [阈值天数]"
    echo "示例: $0 example.com baidu.com:443 30"
    exit 1
fi

echo "===== SSL 证书检查 $(date '+%F %T') (阈值 ${THRESHOLD} 天) ====="
EXIT=0

for target in "${TARGETS[@]}"; do
    host="${target%%:*}"
    port="${target##*:}"
    [ "$port" = "$host" ] && port=443

    expiry=$(echo | timeout 10 openssl s_client -servername "$host" -connect "$host:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$expiry" ]; then
        printf "  [失败] %-30s 无法获取证书\n" "$target"
        EXIT=1
        continue
    fi

    exp_ts=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null)
    now_ts=$(date +%s)
    days=$(( (exp_ts - now_ts) / 86400 ))

    if [ "$days" -lt 0 ]; then
        printf "  [已过期] %-30s 过期于 %s\n" "$target" "$expiry"
        EXIT=1
    elif [ "$days" -le "$THRESHOLD" ]; then
        printf "  [即将过期] %-30s 剩余 %d 天 (%s)\n" "$target" "$days" "$expiry"
        EXIT=1
    else
        printf "  [正常] %-30s 剩余 %d 天\n" "$target" "$days"
    fi
done

exit $EXIT
