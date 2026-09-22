#!/usr/bin/env bash
# 跨发行版/跨平台一键安装常用工具
# 用法: ./一键安装.sh [最小|完整]
# 依赖发行版检测.sh
set -euo pipefail

MODE="${1:-最小}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=发行版检测.sh
source "$SCRIPT_DIR/发行版检测.sh"

echo "===== 一键安装 (模式: $MODE) ====="
echo "系统: $OS_PRETTY | 包管理器: $PKG_MGR"

# 各平台的基础包名映射
base_packages() {
    case "$PKG_MGR" in
        apt)     echo "curl wget vim git htop tree unzip tar jq net-tools dnsutils" ;;
        dnf|yum) echo "curl wget vim git htop tree unzip tar jq net-tools bind-utils" ;;
        pacman)  echo "curl wget vim git htop tree unzip tar jq net-tools bind" ;;
        apk)     echo "curl wget vim git htop tree unzip tar jq net-tools bind-tools" ;;
        zypper)  echo "curl wget vim git htop tree unzip tar jq net-tools bind-utils" ;;
        brew)    echo "curl wget vim git htop tree unzip tar jq rsync" ;;
        *)       echo "curl git" ;;
    esac
}

full_packages() {
    case "$PKG_MGR" in
        apt)     echo "build-essential python3 python3-pip nodejs npm docker.io rsync tmux fail2ban" ;;
        dnf|yum) echo "gcc gcc-c++ make python3 python3-pip nodejs npm docker rsync tmux fail2ban" ;;
        pacman)  echo "base-devel python python-pip nodejs npm docker rsync tmux" ;;
        apk)     echo "build-base python3 py3-pip nodejs npm docker rsync tmux" ;;
        brew)    echo "python node go docker colima kubectl tmux neovim" ;;
        *)       echo "" ;;
    esac
}

echo ""
echo "更新软件包索引..."
pkg_update_index || true

echo "安装基础工具..."
# shellcheck disable=SC2046
pkg_install $(base_packages) || echo "[警告] 部分基础包安装失败"

if [ "$MODE" = "完整" ]; then
    echo "安装完整开发环境..."
    # shellcheck disable=SC2046
    pkg_install $(full_packages) || echo "[警告] 部分完整包安装失败"
fi

# macOS 附加：确保 CLT
if [ "$OS_ID" = "macos" ]; then
    xcode-select -p >/dev/null 2>&1 || xcode-select --install || true
fi

echo ""
echo "===== 安装验证 ====="
for c in curl wget git jq tar; do
    if command -v "$c" >/dev/null 2>&1; then
        echo "  [√] $c"
    else
        echo "  [×] $c"
    fi
done

if [ "$MODE" = "完整" ]; then
    for c in python3 node docker rsync; do
        if command -v "$c" >/dev/null 2>&1; then
            echo "  [√] $c"
        else
            echo "  [×] $c"
        fi
    done
fi

echo ""
echo "完成"
