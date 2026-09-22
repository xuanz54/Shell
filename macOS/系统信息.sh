#!/bin/bash
# macOS 系统信息 - 对应 系统/系统信息.sh
# 用法: ./系统信息.sh
set -euo pipefail

echo "========== 系统信息 =========="
echo "主机名:   $(hostname)"
echo "系统:     macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "代号:     $(sw_vers -productName)"
echo "内核:     $(uname -r)"
echo "架构:     $(uname -m)"
echo "运行时间: $(uptime | sed 's/.*up //' | sed 's/,.*users.*//')"

echo ""
echo "========== 硬件 =========="
system_profiler SPHardwareDataType 2>/dev/null | grep -E "Model Name|Model Identifier|Chip|Processor Name|Processor Speed|Number of Processors|Number of Cores|Memory" | sed 's/^\s*/  /'

echo ""
echo "========== CPU / 负载 =========="
echo "负载: $(sysctl -n vm.loadavg)"
echo "核心数: $(sysctl -n hw.ncpu)"

echo ""
echo "========== 内存 =========="
vm_stat | awk '
    /page size of/ { ps = $8 }
    /Pages free/ { free = $3 }
    /Pages active/ { active = $3 }
    /Pages inactive/ { inactive = $3 }
    /Pages wired/ { wired = $4 }
    /Pages occupied by compressor/ { comp = $5 }
    END {
        gsub(/\./, "", free); gsub(/\./, "", active)
        gsub(/\./, "", inactive); gsub(/\./, "", wired); gsub(/\./, "", comp)
        if (ps == 0) ps = 16384
        printf "  空闲:   %.2f GB\n", free * ps / 1073741824
        printf "  活跃:   %.2f GB\n", active * ps / 1073741824
        printf "  非活跃: %.2f GB\n", inactive * ps / 1073741824
        printf "  有线:   %.2f GB\n", wired * ps / 1073741824
        printf "  压缩:   %.2f GB\n", comp * ps / 1073741824
    }'
sysctl -n hw.memsize | awk '{ printf "  总内存: %.2f GB\n", $1 / 1073741824 }'

echo ""
echo "========== 磁盘 =========="
df -h | grep -E "^/dev/disk|Filesystem" | grep -v EFI | head -10

echo ""
echo "========== 网络 =========="
for i in en0 en1; do
    ip=$(ipconfig getifaddr "$i" 2>/dev/null) && echo "  $i: $ip"
done
echo "  公网: $(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 获取失败)"
