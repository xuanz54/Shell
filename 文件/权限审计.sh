#!/usr/bin/env bash
# 文件权限批量检查与修复（找出 777/666 等危险权限）
# 用法: ./perm-audit.sh [目录] [--fix]
set -uo pipefail

DIR="."
FIX=false
[ "${1:-}" = "--fix" ] && { FIX=true; DIR="${2:-.}"; }
[ "${1:-}" != "--fix" ] && [ -n "${1:-}" ] && DIR="$1"

[ -d "$DIR" ] || { echo "目录不存在: $DIR"; exit 1; }

echo "===== 权限审计: $DIR $(date '+%F %T') ====="

echo ""
echo "-- 全局可写文件（其他人可写）--"
find "$DIR" -type f -perm -0002 2>/dev/null | head -50

echo ""
echo "-- 全局可写目录 --"
find "$DIR" -type d -perm -0002 2>/dev/null | head -50

echo ""
echo "-- SUID 文件 --"
find "$DIR" -type f -perm -4000 2>/dev/null

echo ""
echo "-- 权限为 777 的文件 --"
find "$DIR" -type f -perm 777 2>/dev/null | head -50

if $FIX; then
    echo ""
    echo "-- 修复中: 777 -> 755, 666 -> 644 --"
    find "$DIR" -type f -perm 777 -exec chmod 755 {} + 2>/dev/null || true
    find "$DIR" -type f -perm 666 -exec chmod 644 {} + 2>/dev/null || true
    echo "修复完成"
else
    echo ""
    echo "(预览模式，加 --fix 参数执行修复)"
fi
