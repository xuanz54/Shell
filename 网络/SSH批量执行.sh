#!/usr/bin/env bash
# SSH 批量执行：对多台主机执行相同命令
# 用法: ./ssh-exec.sh -f hosts.txt [-u 用户] [-i 密钥] -- 命令
#   或: ./ssh-exec.sh host1,host2 -- 命令
set -uo pipefail

USER_NAME="${SSH_USER:-$USER}"
KEY=""
HOSTS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -f) mapfile -t HOSTS < "$2"; shift 2 ;;
        -u) USER_NAME="$2"; shift 2 ;;
        -i) KEY="$2"; shift 2 ;;
        --) shift; break ;;
        *) HOSTS+=("$1"); shift ;;
    esac
done

[ $# -eq 0 ] && { echo "用法: $0 [-f hosts.txt] [-u user] [-i key] -- <命令>"; exit 1; }
[ ${#HOSTS[@]} -eq 0 ] && { echo "未指定主机"; exit 1; }

CMD="$*"
SSH_OPTS=(-o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new)
[ -n "$KEY" ] && SSH_OPTS+=(-i "$KEY")

echo "===== SSH 批量执行 $(date '+%F %T') ====="
echo "命令: $CMD"
echo ""

for host in "${HOSTS[@]}"; do
    host=$(echo "$host" | xargs)
    [ -z "$host" ] || [[ "$host" == \#* ]] && continue
    (
        echo "----- $host -----"
        if ssh "${SSH_OPTS[@]}" "$USER_NAME@$host" "$CMD" 2>&1; then
            echo "[$host] 成功"
        else
            echo "[$host] 失败"
        fi
    ) &
done
wait
echo "全部完成"
