#!/usr/bin/env bash
# 一键部署：拉取代码 -> 安装依赖 -> 构建 -> 重启服务
# 用法: ./部署脚本.sh <仓库地址> <项目目录> [服务名]
set -euo pipefail

REPO="${1:-}"
DIR="${2:-}"
SERVICE="${3:-}"

[ -n "$REPO" ] && [ -n "$DIR" ] || { echo "用法: $0 <仓库地址> <项目目录> [服务名]"; exit 1; }

log() { echo "[$(date '+%F %T')] $*"; }

log "===== 开始部署 ====="

if [ -d "$DIR/.git" ]; then
    log "拉取更新..."
    git -C "$DIR" pull --ff-only
else
    log "克隆仓库..."
    git clone "$REPO" "$DIR"
fi

cd "$DIR"

if [ -f package.json ]; then
    log "安装 Node 依赖..."
    if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile
    else npm ci; fi
    log "构建..."
    npm run build --if-present
elif [ -f requirements.txt ]; then
    log "安装 Python 依赖..."
    python3 -m pip install -r requirements.txt
elif [ -f go.mod ]; then
    log "构建 Go..."
    go build ./...
elif [ -f Makefile ]; then
    log "执行 make..."
    make -j"$(nproc 2>/dev/null || echo 2)"
fi

if [ -n "$SERVICE" ] && command -v systemctl >/dev/null 2>&1; then
    log "重启服务: $SERVICE"
    sudo systemctl restart "$SERVICE"
    sudo systemctl --no-pager -l status "$SERVICE" | head -5
fi

log "===== 部署完成 ====="
