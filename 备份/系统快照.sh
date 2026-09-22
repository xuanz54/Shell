#!/usr/bin/env bash
# 系统/应用配置快照备份（/etc、crontab、已安装包列表）
# 用法: ./snapshot-system.sh [输出目录]
set -euo pipefail

DEST="${1:-/backup/snapshots}"
STAMP=$(date +%Y%m%d_%H%M%S)
OUT="$DEST/system_snapshot_$STAMP.tar.gz"

mkdir -p "$DEST"
TMPDIR_S=$(mktemp -d)
trap 'rm -rf "$TMPDIR_S"' EXIT

echo "[$(date '+%F %T')] 收集系统配置..."

# /etc 关键配置
cp -a /etc "$TMPDIR_S/etc" 2>/dev/null || true

# crontab
crontab -l > "$TMPDIR_S/crontab_root.txt" 2>/dev/null || true

# 软件包列表
{ command -v dpkg >/dev/null && dpkg --get-selections > "$TMPDIR_S/packages_dpkg.txt"
  command -v rpm  >/dev/null && rpm -qa > "$TMPDIR_S/packages_rpm.txt"
  command -v apk  >/dev/null && apk info -v > "$TMPDIR_S/packages_apk.txt"
} 2>/dev/null || true

# 网络与内核
ip addr > "$TMPDIR_S/ip_addr.txt" 2>/dev/null || true
ip route > "$TMPDIR_S/ip_route.txt" 2>/dev/null || true
uname -a > "$TMPDIR_S/uname.txt"

tar -czf "$OUT" -C "$TMPDIR_S" .
ls -lh "$OUT"
echo "[$(date '+%F %T')] 快照完成: $OUT"
