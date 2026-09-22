#!/usr/bin/env bash
# 服务管理统一接口 - systemd / OpenRC / SysV / launchd
# 用法: ./服务管理对照.sh status 服务名
#        ./服务管理对照.sh start|stop|restart|enable|disable 服务名
#        ./服务管理对照.sh list
# 也可 source 后直接调用 svc_* 函数（见 发行版检测.sh）
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=发行版检测.sh
source "$SCRIPT_DIR/发行版检测.sh"

usage() {
    cat <<EOF
用法: $0 <操作> [服务名]
操作:
  status|start|stop|restart|enable|disable  服务操作
  list                                       列出服务
  detect                                     显示检测结果
当前检测: 服务管理器 = $SVC_MGR
EOF
    exit 1
}

list_services() {
    case "$SVC_MGR" in
        systemd)  systemctl list-units --type=service --no-pager ;;
        openrc)   rc-status ;;
        sysv)     ls /etc/init.d/ 2>/dev/null ;;
        launchd)
            echo "-- 用户/系统服务 --"
            launchctl list | head -30
            if command -v brew >/dev/null 2>&1; then
                echo ""
                echo "-- Homebrew services --"
                brew services list 2>/dev/null
            fi
            ;;
        *) echo "未知服务管理器"; exit 1 ;;
    esac
}

ACTION="${1:-}"
NAME="${2:-}"

case "$ACTION" in
    status|start|stop|restart|enable|disable)
        [ -n "$NAME" ] || usage
        svc_action "$ACTION" "$NAME"
        ;;
    list)
        list_services
        ;;
    detect)
        echo "系统:     $OS_PRETTY"
        echo "包管理器: $PKG_MGR"
        echo "服务管理: $SVC_MGR"
        ;;
    *)
        usage
        ;;
esac
