#!/usr/bin/env bash
# 批量创建用户（含 SSH 公钥、sudo 权限）
# 用法: ./批量创建用户.sh -f users.txt [-s 公钥文件] [-p 初始密码] [-g sudo组]
#   users.txt 格式: 每行一个用户名
set -euo pipefail

USERS_FILE=""
PUBKEY=""
PASSWORD=""
SUDO_GROUP="sudo"

while [ $# -gt 0 ]; do
    case "$1" in
        -f) USERS_FILE="$2"; shift 2 ;;
        -s) PUBKEY="$2"; shift 2 ;;
        -p) PASSWORD="$2"; shift 2 ;;
        -g) SUDO_GROUP="$2"; shift 2 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

[ -n "$USERS_FILE" ] && [ -f "$USERS_FILE" ] || { echo "用法: $0 -f users.txt [-s pubkey] [-p password] [-g 组]"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "请用 root 运行"; exit 1; }

# 兼容 CentOS 的 wheel 组
getent group wheel >/dev/null 2>&1 && [ "$SUDO_GROUP" = "sudo" ] && SUDO_GROUP="wheel"

echo "===== 批量创建用户 $(date '+%F %T') ====="

while IFS= read -r user; do
    user=$(echo "$user" | xargs)
    [ -z "$user" ] || [[ "$user" == \#* ]] && continue

    if id "$user" >/dev/null 2>&1; then
        echo "  [跳过] 用户已存在: $user"
        continue
    fi

    useradd -m -s /bin/bash "$user"
    if [ -n "$PASSWORD" ]; then
        echo "$user:$PASSWORD" | chpasswd
    else
        passwd -l "$user" 2>/dev/null || true
        echo "  [提示] $user 密码已锁定，需设置密码或用密钥登录"
    fi

    if [ -n "$PUBKEY" ] && [ -f "$PUBKEY" ]; then
        mkdir -p "/home/$user/.ssh"
        chmod 700 "/home/$user/.ssh"
        cat "$PUBKEY" >> "/home/$user/.ssh/authorized_keys"
        chmod 600 "/home/$user/.ssh/authorized_keys"
        chown -R "$user:$user" "/home/$user/.ssh"
    fi

    usermod -aG "$SUDO_GROUP" "$user" 2>/dev/null && echo "  [创建] $user (加入 $SUDO_GROUP)" \
        || echo "  [创建] $user"
done < "$USERS_FILE"

echo "完成。当前用户列表:"
awk -F: '$3>=1000 && $3<65534 {print "  "$1}' /etc/passwd
