#!/usr/bin/env bash
# 批量 Ping 检测：检查主机列表连通性
# 用法: ./ping-check.sh host1 host2 ...
#   或: ./ping-check.sh -f hosts.txt   # 从文件读取，每行一个
set -uo pipefail

HOSTS=()
if [ "${1:-}" = "-f" ]; then
    [ -f "${2:-}" ] || { echo "文件不存在: ${2:-}"; exit 1; }
    mapfile -t HOSTS < "$2"
else
    HOSTS=("$@")
fi

[ ${#HOSTS[@]} -eq 0 ] && { echo "用法: $0 host1 host2 ... | $0 -f hosts.txt"; exit 1; }

UP=0; DOWN=0; FAILED_LIST=()

echo "===== Ping 检测 $(date '+%F %T') ====="
for host in "${HOSTS[@]}"; do
    host=$(echo "$host" | xargs)
    [ -z "$host" ] && [[ "$host" == \#* ]] && continue
    if ping -c 2 -W 2 "$host" >/dev/null 2>&1; then
        printf "  [通]   %s\n" "$host"
        UP=$((UP + 1))
    else
        printf "  [不通] %s\n" "$host"
        DOWN=$((DOWN + 1))
        FAILED_LIST+=("$host")
    fi
done

echo ""
echo "结果: 通 $UP / 不通 $DOWN"
if [ ${#FAILED_LIST[@]} -gt 0 ]; then
    echo "不可达主机: ${FAILED_LIST[*]}"
    exit 1
fi
