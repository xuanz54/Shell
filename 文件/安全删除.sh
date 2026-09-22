#!/usr/bin/env bash
# 安全删除文件（多次覆写后删除）
# 用法: ./secure-delete.sh <文件或目录>
set -euo pipefail

TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "用法: $0 <文件或目录>"; exit 1; }
[ -e "$TARGET" ] || { echo "不存在: $TARGET"; exit 1; }

shred() {
    local f="$1"
    if command -v shred >/dev/null 2>&1; then
        shred -u -n 3 -- "$f"
        echo "[已覆写删除] $f"
    else
        # 无 shred 时用 dd 覆写
        size=$(stat -c%s "$f" 2>/dev/null || wc -c < "$f")
        if [ "$size" -gt 0 ]; then
            head -c "$size" /dev/urandom > "$f"
            head -c "$size" /dev/zero > "$f" 2>/dev/null || true
        fi
        rm -f -- "$f"
        echo "[随机+零覆写删除] $f"
    fi
}

if [ -f "$TARGET" ]; then
    shred "$TARGET"
elif [ -d "$TARGET" ]; then
    find "$TARGET" -type f -print0 | while IFS= read -r -d '' f; do
        shred "$f"
    done
    rm -rf -- "$TARGET"
    echo "[目录已删除] $TARGET"
fi

echo "完成"
