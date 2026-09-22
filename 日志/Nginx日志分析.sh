#!/usr/bin/env bash
# Nginx 访问日志分析：Top IP、Top URL、状态码、流量
# 用法: ./Nginx日志分析.sh [日志文件] [日期, 如 22/Sep/2026]
set -uo pipefail

LOG_FILE="${1:-/var/log/nginx/access.log}"
DATE="${2:-}"

[ -f "$LOG_FILE" ] || { echo "日志不存在: $LOG_FILE"; exit 1; }

echo "===== Nginx 日志分析: $LOG_FILE ====="
[ -n "$DATE" ] && echo "过滤日期: $DATE" && FILTER="grep '$DATE'" || FILTER="cat"

echo ""
echo "-- 请求总量 --"
eval "$FILTER '$LOG_FILE'" | wc -l

echo ""
echo "-- Top 10 客户端 IP --"
eval "$FILTER '$LOG_FILE'" | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "-- Top 10 请求 URL --"
eval "$FILTER '$LOG_FILE'" | awk '{print $7}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "-- 状态码分布 --"
eval "$FILTER '$LOG_FILE'" | awk '{print $9}' | sort | uniq -c | sort -rn

echo ""
echo "-- Top 10 错误请求 (4xx/5xx) --"
eval "$FILTER '$LOG_FILE'" | awk '$9 >= 400 {print $9, $7}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "-- 每小时请求量 --"
eval "$FILTER '$LOG_FILE'" | awk -F'[\\[\\]]' '{print substr($2,1,14)}' | uniq -c | tail -24
