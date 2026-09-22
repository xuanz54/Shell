#!/usr/bin/env bash
# 批量重置用户密码
# 用法: ./批量改密码.sh -f users.txt [-p 新密码 | -r 随机]
set -euo pipefail

USERS_FILE=""
MODE=""
PASSWORD=""

while [ $# -gt 0 ]; do
    case "$1" in
        -f) USERS_FILE="$2"; shift 2 ;;
        -p) MODE="fixed"; PASSWORD="$2"; shift 2 ;;
        -r) MODE="random"; shift ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

[ -n "$USERS_FILE" ] && [ -f "$USERS_FILE" ] || { echo "用法: $0 -f users.txt [-p 密码 | -r]"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "请用 root 运行"; exit 1; }
[ -n "$MODE" ] || { echo "请指定 -p 密码 或 -r 随机生成"; exit 1; }

gen_pass() {
    tr -dc 'A-Za-z0-9@#%^-_' < /dev/urandom | head -c "${1:-16}"
}

echo "===== 批量改密码 $(date '+%F %T') ====="

while IFS= read -r user; do
    user=$(echo "$user" | xargs)
    [ -z "$user" ] || [[ "$user" == \#* ]] && continue

    id "$user" >/dev/null 2>&1 || { echo "  [跳过] 用户不存在: $user"; continue; }

    if [ "$MODE" = "random" ]; then
        PASSWORD=$(gen_pass 16)
        echo "$user:$PASSWORD" | chpasswd
        echo "  [已重置] $user -> $PASSWORD"
    else
        echo "$user:$PASSWORD" | chpasswd
        echo "  [已重置] $user"
    fi
done < "$USERS_FILE"

echo "完成"
