#!/usr/bin/env bash
# HTTP 接口健康检查（支持状态码、响应时间、关键词）
# 用法: ./http-health.sh <url> [期望状态码] [超时秒] [包含关键词]
set -uo pipefail

URL="${1:-}"
EXPECT_CODE="${2:-200}"
TIMEOUT="${3:-10}"
KEYWORD="${4:-}"

[ -z "$URL" ] && { echo "用法: $0 <url> [expect_code] [timeout] [keyword]"; echo "示例: $0 https://example.com 200 5 ok"; exit 1; }

START=$(date +%s%3N 2>/dev/null || date +%s)
HTTP_CODE=$(curl -sS -o /tmp/http_health_body.$$ -w "%{http_code}" --max-time "$TIMEOUT" "$URL" 2>/dev/null || echo "000")
END=$(date +%s%3N 2>/dev/null || date +%s)
COST=$((END - START))
[ "$(echo "$COST / 1000" | bc 2>/dev/null || echo "$COST")" = "$COST" ] && [ "$COST" -gt 1000 ] && COST_MS=$COST || COST_MS=$COST

OK=true
[ "$HTTP_CODE" != "$EXPECT_CODE" ] && OK=false

if [ -n "$KEYWORD" ]; then
    grep -q "$KEYWORD" /tmp/http_health_body.$$ 2>/dev/null || OK=false
fi

rm -f /tmp/http_health_body.$$

echo "URL:      $URL"
echo "状态码:   $HTTP_CODE (期望 $EXPECT_CODE)"
echo "耗时:     ${COST_MS}ms"
echo "超时:     ${TIMEOUT}s"

if $OK; then
    echo "结果:     [健康]"
    exit 0
else
    echo "结果:     [异常]"
    exit 1
fi
