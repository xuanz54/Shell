#!/usr/bin/env bash
# 系统清理：软件包缓存、临时文件、旧日志、孤儿依赖
# 用法: sudo ./cleanup-system.sh [-y]
set -euo pipefail

YES=false
[ "${1:-}" = "-y" ] && YES=true

run() {
    echo ">>> $*"
    if $YES; then "$@"; else read -r -p "执行? [y/N] " ans && [[ "$ans" =~ ^[Yy]$ ]] && "$@" || echo "  跳过"; fi
}

echo "===== 系统清理 $(date '+%F %T') ====="

# 1. 软件包缓存
if command -v apt-get >/dev/null 2>&1; then
    run sudo apt-get clean
    run sudo apt-get autoremove -y
elif command -v yum >/dev/null 2>&1; then
    run sudo yum clean all
elif command -v dnf >/dev/null 2>&1; then
    run sudo dnf clean all
elif command -v apk >/dev/null 2>&1; then
    run sudo apk cache clean 2>/dev/null || true
fi

# 2. 临时文件（保留当前会话）
if [ -d /tmp ]; then
    run find /tmp -type f -atime +7 -delete 2>/dev/null || true
fi

# 3. 旧日志（保留 14 天）
if command -v journalctl >/dev/null 2>&1; then
    run sudo journalctl --vacuum-time=14d
fi
[ -d /var/log ] && run sudo find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null || true

# 4. 用户回收站
[ -d "$HOME/.local/share/Trash/files" ] && run rm -rf "$HOME/.local/share/Trash/files"/* 2>/dev/null || true

echo ""
echo "清理完成，当前磁盘使用:"
df -h / | tail -1
