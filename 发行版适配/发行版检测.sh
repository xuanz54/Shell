#!/usr/bin/env bash
# 发行版/系统检测 - 输出可被其他脚本 source 的变量
# 用法: source 发行版检测.sh 后使用:
#   $OS_ID $OS_VERSION $OS_LIKE $PKG_MGR $SVC_MGR $IS_ROOT $ARCH
#   pkg_install 包1 包2    # 统一安装
#   svc_status|start|stop|restart 服务名
set -uo pipefail

detect_os() {
    OS_ID="unknown"
    OS_VERSION=""
    OS_LIKE=""
    OS_PRETTY=""

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-}"
        OS_LIKE="${ID_LIKE:-}"
        OS_PRETTY="${PRETTY_NAME:-}"
    elif [ "$(uname)" = "Darwin" ]; then
        OS_ID="macos"
        OS_VERSION="$(sw_vers -productVersion 2>/dev/null || true)"
        OS_PRETTY="macOS $OS_VERSION"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        OS_ID="wsl"
        OS_PRETTY="Windows Subsystem for Linux"
    elif [ "$(uname -s)" = "Linux" ]; then
        OS_ID="linux"
        OS_PRETTY="Linux $(uname -r)"
    fi

    ARCH="$(uname -m)"
}

detect_pkg_mgr() {
    PKG_MGR="unknown"
    if   command -v apt-get  >/dev/null 2>&1; then PKG_MGR=apt
    elif command -v dnf      >/dev/null 2>&1; then PKG_MGR=dnf
    elif command -v yum      >/dev/null 2>&1; then PKG_MGR=yum
    elif command -v pacman   >/dev/null 2>&1; then PKG_MGR=pacman
    elif command -v zypper   >/dev/null 2>&1; then PKG_MGR=zypper
    elif command -v apk      >/dev/null 2>&1; then PKG_MGR=apk
    elif command -v brew     >/dev/null 2>&1; then PKG_MGR=brew
    elif command -v winget   >/dev/null 2>&1; then PKG_MGR=winget
    elif command -v emerge   >/dev/null 2>&1; then PKG_MGR=emerge
    fi
}

detect_svc_mgr() {
    SVC_MGR="unknown"
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        SVC_MGR=systemd
    elif command -v rc-service >/dev/null 2>&1; then
        SVC_MGR=openrc
    elif command -v initctl >/dev/null 2>&1 && [ -d /etc/init ]; then
        SVC_MGR=upstart
    elif command -v service >/dev/null 2>&1; then
        SVC_MGR=sysv
    elif [ "$(uname)" = "Darwin" ] && command -v launchctl >/dev/null 2>&1; then
        SVC_MGR=launchd
    elif command -v sc >/dev/null 2>&1; then
        SVC_MGR=windows
    fi
}

detect_root() {
    IS_ROOT=false
    [ "$(id -u)" -eq 0 ] && IS_ROOT=true
}

# 统一安装
pkg_install() {
    [ $# -gt 0 ] || { echo "用法: pkg_install 包..."; return 1; }
    case "$PKG_MGR" in
        apt)     sudo apt-get install -y "$@" ;;
        dnf)     sudo dnf install -y "$@" ;;
        yum)     sudo yum install -y "$@" ;;
        pacman)  sudo pacman -S --noconfirm "$@" ;;
        zypper)  sudo zypper --non-interactive install "$@" ;;
        apk)     sudo apk add "$@" ;;
        brew)    brew install "$@" ;;
        emerge)  sudo emerge -q "$@" ;;
        winget)  winget install -e "$@" ;;
        *)       echo "不支持的包管理器: $PKG_MGR"; return 1 ;;
    esac
}

pkg_update_index() {
    case "$PKG_MGR" in
        apt)     sudo apt-get update -y ;;
        dnf)     sudo dnf check-update || true ;;
        yum)     sudo yum check-update || true ;;
        pacman)  sudo pacman -Sy --noconfirm ;;
        zypper)  sudo zypper refresh ;;
        apk)     sudo apk update ;;
        brew)    brew update ;;
        *)       echo "无需或不支持更新索引: $PKG_MGR" ;;
    esac
}

# 统一服务管理
svc_action() {
    local action="$1" name="$2"
    case "$SVC_MGR" in
        systemd)
            case "$action" in
                status)  systemctl status "$name" --no-pager ;;
                start)   sudo systemctl start "$name" ;;
                stop)    sudo systemctl stop "$name" ;;
                restart) sudo systemctl restart "$name" ;;
                enable)  sudo systemctl enable "$name" ;;
                disable) sudo systemctl disable "$name" ;;
            esac ;;
        openrc)
            case "$action" in
                status)  rc-service "$name" status ;;
                start)   sudo rc-service "$name" start ;;
                stop)    sudo rc-service "$name" stop ;;
                restart) sudo rc-service "$name" restart ;;
                enable)  sudo rc-update add "$name" default ;;
                disable) sudo rc-update del "$name" default ;;
            esac ;;
        sysv)
            case "$action" in
                status|start|stop|restart) sudo service "$name" "$action" ;;
                *) echo "SysV 不支持 $action（试用 chkconfig/update-rc.d）"; return 1 ;;
            esac ;;
        launchd)
            case "$action" in
                status) launchctl print "system/$name" 2>/dev/null || launchctl list "$name" ;;
                start)  sudo launchctl kickstart -k "system/$name" 2>/dev/null || launchctl load "$name" ;;
                stop)   sudo launchctl bootout "system/$name" 2>/dev/null || launchctl unload "$name" ;;
                restart) svc_action stop "$name" && svc_action start "$name" ;;
                *) echo "launchd 不支持 $action" ;;
            esac ;;
        *)
            echo "未知服务管理器: $SVC_MGR"; return 1 ;;
    esac
}

# 兼容别名
svc_status()  { svc_action status "$@"; }
svc_start()   { svc_action start "$@"; }
svc_stop()    { svc_action stop "$@"; }
svc_restart() { svc_action restart "$@"; }

# 执行检测
detect_os
detect_pkg_mgr
detect_svc_mgr
detect_root

# 直接运行时打印（被 source 时不打印）
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "===== 系统检测结果 ====="
    echo "系统:     $OS_PRETTY (ID=$OS_ID version=$OS_VERSION like=$OS_LIKE)"
    echo "架构:     $ARCH"
    echo "包管理器: $PKG_MGR"
    echo "服务管理: $SVC_MGR"
    echo "Root:     $IS_ROOT"
    echo ""
    echo "示例:"
    echo "  source $0"
    echo "  pkg_install curl git jq"
    echo "  svc_restart nginx"
fi
