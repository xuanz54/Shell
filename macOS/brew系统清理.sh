#!/bin/bash
# macOS 系统清理（brew 缓存、系统缓存、日志、回收站） - 对应 系统/系统清理.sh
# 用法: ./brew系统清理.sh [-y]
set -uo pipefail

YES=false
[ "${1:-}" = "-y" ] && YES=true

run() {
    echo ">>> $*"
    if $YES; then "$@"; else
        read -r -p "执行? [y/N] " ans && [[ "$ans" =~ ^[Yy]$ ]] && "$@"
    fi
}

echo "===== macOS 系统清理 $(date '+%F %T') ====="

# 1. Homebrew
if command -v brew >/dev/null 2>&1; then
    run brew cleanup -s
    run rm -rf "$(brew --cache)" 2>/dev/null || true
fi

# 2. 用户缓存
run find "$HOME/Library/Caches" -type f -atime +30 -delete 2>/dev/null || true

# 3. 系统日志（保留 7 天）
run find /private/var/log -type f -mtime +7 -delete 2>/dev/null || true

# 4. 用户日志
run find "$HOME/Library/Logs" -type f -mtime +30 -delete 2>/dev/null || true

# 5. 回收站
if [ -d "$HOME/.Trash" ]; then
    run find "$HOME/.Trash" -mindepth 1 -delete 2>/dev/null || true
fi

# 6. 快速查看缩略图缓存（会重建）
run find "$HOME/Library/Caches/com.apple.QuickLook.thumbnailcache" -delete 2>/dev/null || true

echo ""
echo "清理完成，磁盘状态:"
df -h /
echo ""
echo "可用内存:"
vm_stat | head -4
