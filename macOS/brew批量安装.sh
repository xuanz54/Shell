#!/bin/bash
# macOS Homebrew 批量安装 - 开发环境一键装
# 用法: ./brew批量安装.sh [最小|完整]
set -euo pipefail

MODE="${1:-最小}"

if ! command -v brew >/dev/null 2>&1; then
    echo "未安装 Homebrew，正在安装..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon 默认路径
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

echo "===== Homebrew 批量安装 (模式: $MODE) ====="

BASE_PKGS=(
    git curl wget jq tree htop
    coreutils gnu-sed grep
    unzip zip p7zip
    rsync tmux
)

FULL_PKGS=(
    python node go
    nginx redis
    docker colima kubectl helm
    fzf ripgrep fd bat
    neovim
)

echo "更新 brew..."
brew update

echo "安装基础工具..."
brew install "${BASE_PKGS[@]}" 2>/dev/null || brew install "${BASE_PKGS[@]}"

if [ "$MODE" = "完整" ]; then
    echo "安装完整开发环境..."
    brew install "${FULL_PKGS[@]}" 2>/dev/null || true
    brew install --cask visual-studio-code 2>/dev/null || true
fi

echo ""
echo "===== 安装结果 ====="
for c in git curl jq tree htop python3 node go docker; do
    if command -v "$c" >/dev/null 2>&1; then
        echo "  [√] $c"
    else
        echo "  [×] $c"
    fi
done
echo ""
echo "brew 包数量: $(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"
