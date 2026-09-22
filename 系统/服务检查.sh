#!/usr/bin/env bash
# 服务状态检查（systemd），失败时报警
# 用法: ./service-check.sh nginx ssh docker ...
#   或: ./service-check.sh          # 检查下方默认列表
set -uo pipefail

DEFAULT_SERVICES=(nginx ssh docker)
SERVICES=("${@:-${DEFAULT_SERVICES[@]}}")
FAILED=()

echo "===== 服务状态检查 $(date '+%F %T') ====="

if ! command -v systemctl >/dev/null 2>&1; then
    echo "错误: 未找到 systemctl，仅支持 systemd 系统"
    exit 2
fi

for svc in "${SERVICES[@]}"; do
    [ -z "$svc" ] && continue
    if systemctl is-active --quiet "$svc"; then
        printf "  [正常] %-20s %s\n" "$svc" "$(systemctl is-active "$svc")"
    else
        printf "  [异常] %-20s %s\n" "$svc" "$(systemctl is-active "$svc" 2>&1)"
        FAILED+=("$svc")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "[警告] 以下服务异常: ${FAILED[*]}"
    # 如需邮件/钉钉/Webhook 报警，在此处扩展
    exit 1
fi

echo "全部服务正常"
