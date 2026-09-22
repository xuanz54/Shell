#!/usr/bin/env bash
# 环境初始化：常用工具、开发环境一键安装（Debian/Ubuntu/CentOS）
# 用法: sudo ./环境初始化.sh [最小|完整]
set -euo pipefail

MODE="${1:-最小}"

[ "$(id -u)" -eq 0 ] || SUDO="sudo" || SUDO=""

detect_pkg() {
    if command -v apt-get >/dev/null 2>&1; then echo "apt"
    elif command -v dnf >/dev/null 2>&1; then echo "dnf"
    elif command -v yum >/dev/null 2>&1; then echo "yum"
    elif command -v apk >/dev/null 2>&1; then echo "apk"
    else echo "unknown"; fi
}

PKG=$(detect_pkg)
echo "===== 环境初始化 (模式: $MODE, 包管理: $PKG) ====="

BASE_PKGS=(curl wget vim git htop tree unzip tar jq net-tools dnsutils)
FULL_PKGS+=(build-essential python3 python3-pip nodejs npm docker.io rsync tmux)

install_pkgs() {
    local pkgs=("$@")
    case "$PKG" in
        apt) $SUDO apt-get update -y && $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}" ;;
        dnf) $SUDO dnf install -y "${pkgs[@]}" ;;
        yum) $SUDO yum install -y "${pkgs[@]}" ;;
        apk) $SUDO apk add --no-cache "${pkgs[@]}" ;;
        *) echo "不支持的包管理器"; exit 1 ;;
    esac
}

echo "安装基础工具..."
install_pkgs "${BASE_PKGS[@]}"

if [ "$MODE" = "完整" ]; then
    echo "安装完整开发环境..."
    install_pkgs "${FULL_PKGS[@]}" || true
fi

# 时区
if [ -f /usr/share/zoneinfo/Asia/Shanghai ]; then
    $SUDO timedatectl set-timezone Asia/Shanghai 2>/dev/null || true
fi

# 常用 sysctl 优化
if [ "$(id -u)" -eq 0 ]; then
    cat > /etc/sysctl.d/99-custom.conf <<'EOF'
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
vm.swappiness = 10
fs.file-max = 1000000
EOF
    sysctl --system >/dev/null 2>&1 || true
fi

echo ""
echo "===== 初始化完成 ====="
echo "已安装:"
for c in curl wget vim git htop tree jq python3 node docker; do
    command -v "$c" >/dev/null 2>&1 && echo "  [√] $c" || echo "  [×] $c"
done
