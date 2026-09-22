#!/usr/bin/env bash
# 错误日志监控告警（发现新错误行时通过 Webhook 通知）
# 用法: ./错误日志告警.sh <日志文件> [状态文件] [Webhook URL]
#   支持企业微信/钉钉/飞书通用 Webhook（text 格式）
set -uo pipefail

LOG_FILE="${1:-}"
STATE_FILE="${2:-/tmp/err_alert.state}"
WEBHOOK="${3:-${WEBHOOK_URL:-}}"

[ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ] || { echo "用法: $0 <日志文件> [状态文件] [webhook]"; exit 1; }

HOST=$(hostname)
ERROR_PATTERN="${ERROR_PATTERN:-ERROR|Error|FATAL|Exception|失败|错误}"

# 记录上次读取位置
if [ -f "$STATE_FILE" ]; then
    OFFSET=$(cat "$STATE_FILE")
else
    OFFSET=$(wc -c < "$LOG_FILE")
    echo "$OFFSET" > "$STATE_FILE"
fi

SIZE=$(wc -c < "$LOG_FILE")
if [ "$SIZE" -lt "$OFFSET" ]; then
    OFFSET=0  # 日志被轮转
fi

NEW_LINES=$(tail -c +"$((OFFSET + 1))" "$LOG_FILE" 2>/dev/null)
echo "$SIZE" > "$STATE_FILE"

ALERTS=$(echo "$NEW_LINES" | grep -E "$ERROR_PATTERN" | tail -50)
COUNT=$(echo "$ALERTS" | grep -c . || true)

if [ "$COUNT" -eq 0 ]; then
    exit 0
fi

echo "发现 $COUNT 条新错误:"
echo "$ALERTS" | head -10

# Webhook 通知
if [ -n "$WEBHOOK" ]; then
    MSG="【$HOST 日志告警】新错误 $COUNT 条
$(echo "$ALERTS" | head -5)"
    PAYLOAD=$(printf '{"msgtype":"text","text":{"content":"%s"}}' "$(echo "$MSG" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')")
    curl -sS -m 5 -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK" >/dev/null 2>&1 \
        && echo "已发送告警" || echo "告警发送失败"
fi

exit 1
