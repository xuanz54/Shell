#!/usr/bin/env bash
# Docker 清理：悬空镜像、停止容器、未用网络、构建缓存
# 用法: ./Docker清理.sh [-y]
set -euo pipefail

command -v docker >/dev/null 2>&1 || { echo "未安装 docker"; exit 1; }

YES=false
[ "${1:-}" = "-y" ] && YES=true

echo "===== Docker 清理前占用 ====="
docker system df

confirm() {
    if $YES; then return 0; fi
    read -r -p "$1 [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

echo ""
if confirm "清理停止的容器?"; then
    docker container prune -f
fi

echo ""
if confirm "清理悬空(未被标记)镜像?"; then
    docker image prune -f
fi

echo ""
if confirm "清理未使用的网络?"; then
    docker network prune -f
fi

echo ""
if confirm "清理未使用的数据卷? (危险)"; then
    docker volume prune -f
fi

echo ""
if confirm "清理构建缓存?"; then
    docker builder prune -f
fi

echo ""
echo "===== 清理后占用 ====="
docker system df
