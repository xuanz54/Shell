#!/usr/bin/env bash
# 查找重复文件（按 MD5）
# 用法: ./find-duplicates.sh [目录]
set -uo pipefail

DIR="${1:-.}"
[ -d "$DIR" ] || { echo "目录不存在: $DIR"; exit 1; }

echo "===== 重复文件查找: $DIR $(date '+%F %T') ====="
echo "计算中，请稍候..."

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

find "$DIR" -type f -size +0c -print0 2>/dev/null \
    | xargs -0 md5sum 2>/dev/null \
    | sort > "$TMP"

# 输出有重复哈希的组
awk '
{
    hash=$1; $1=""; sub(/^ /,""); file=$0
    files[hash]=files[hash] "\n  " file
    count[hash]++
}
END {
    groups=0
    for (h in count)
        if (count[h] > 1) {
            groups++
            print "[" groups "] MD5: " h " (重复 " count[h] " 次)"
            print files[h]
            print ""
        }
    if (groups == 0) print "未发现重复文件"
    else print "共 " groups " 组重复文件"
}' "$TMP"
