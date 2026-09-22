#!/bin/bash
# macOS 服务(launchd)检查 - 对应 系统/服务检查.sh
# 用法: ./服务检查.sh [label1] [label2] ...
#   默认检查常见服务 label
set -uo pipefail

DEFAULT_SERVICES=(
    com.openssh.sshd
    com.apple.Dock
    homebrew.mxcl.nginx
    homebrew.mxcl.redis
)
SERVICES=("${@:-${DEFAULT_SERVICES[@]}}")

echo "===== launchd 服务检查 $(date '+%F %T') ====="

# 也列出 brew 服务（若安装）
if command -v brew >/dev/null 2>&1; then
    echo ""
    echo "-- Homebrew services --"
    brew services list 2>/dev/null || true
fi

echo ""
echo "-- 指定 label 状态 --"
FAILED=0
for label in "${SERVICES[@]}"; do
    [ -z "$label" ] && continue
    # launchctl print 系统域优先，失败则用户域
    if out=$(launchctl print "system/$label" 2>/dev/null); then
        state=$(echo "$out" | awk -F'= ' '/state =/{print $2; exit}')
        printf "  [system] %-40s %s\n" "$label" "${state:-unknown}"
    elif out=$(launchctl print "gui/$(id -u)/$label" 2>/dev/null); then
        state=$(echo "$out" | awk -F'= ' '/state =/{print $2; exit}')
        printf "  [user]   %-40s %s\n" "$label" "${state:-unknown}"
    else
        printf "  [未找到] %s\n" "$label"
        # 未找到不算致命（可选服务）
    fi
done

echo ""
echo "-- 运行中的第三方服务 --"
launchctl list 2>/dev/null | grep -v "^\-" | grep -vE "com\.apple\." | head -20 || true
