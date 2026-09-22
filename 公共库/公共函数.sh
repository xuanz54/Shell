#!/usr/bin/env bash
# 公共函数库 - 在其他脚本中 source 引用
# 用法: source "$(dirname "$0")/../公共库/公共函数.sh"

# 颜色输出
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

log_info()  { echo -e "${GREEN}[信息]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[警告]${NC} $*" >&2; }
log_error() { echo -e "${RED}[错误]${NC} $*" >&2; }
log_step()  { echo -e "${BLUE}[步骤]${NC} $*"; }

# 时间戳日志
log_ts() { echo "[$(date '+%F %T')] $*"; }

# 确认提示: confirm "是否继续?" && do_something
confirm() {
    local msg="${1:-确认执行?}"
    read -r -p "$msg [y/N] " ans
    [[ "$ans" =~ ^[Yy] ]]
}

# 检查命令是否存在: require curl git
require() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少命令: ${missing[*]}"
        return 1
    fi
}

# 检查是否 root
is_root() { [ "$(id -u)" -eq 0 ]; }

# 需要 root 则提权提示
need_root() {
    is_root || { log_error "请用 root/sudo 运行"; exit 1; }
}

# 加锁（防止重复运行）: flock_lock /path/lock
flock_lock() {
    local lockfile="$1"
    exec 200>"$lockfile"
    flock -n 200 || { log_warn "另一个实例正在运行"; exit 1; }
}

# 带重试的命令: retry 3 5 curl -sS URL  (次数 间隔 命令)
retry() {
    local times="$1" delay="$2"; shift 2
    local i=1
    while true; do
        "$@" && return 0
        if [ "$i" -ge "$times" ]; then
            log_error "重试 $times 次仍失败: $*"
            return 1
        fi
        log_warn "第 $i 次失败，${delay}s 后重试..."
        sleep "$delay"
        i=$((i + 1))
    done
}

# 文件加锁式备份: backup_file /etc/nginx/nginx.conf
backup_file() {
    local f="$1"
    [ -f "$f" ] || { log_error "文件不存在: $f"; return 1; }
    local b="${f}.$(date +%Y%m%d_%H%M%S).bak"
    cp -a "$f" "$b"
    log_info "已备份: $b"
    echo "$b"
}

# 人类可读大小
human_size() {
    numfmt --to=iec "$1" 2>/dev/null || echo "$1 B"
}

# 生成随机密码
gen_password() {
    local len="${1:-16}"
    tr -dc 'A-Za-z0-9@#%^-_' < /dev/urandom | head -c "$len"
}

# Webhook 通知（企业微信/钉钉/飞书 text 格式通用）
notify() {
    local msg="$1"
    local webhook="${WEBHOOK_URL:-}"
    [ -n "$webhook" ] || { log_warn "未设置 WEBHOOK_URL，跳过通知"; return 0; }
    local payload
    payload=$(printf '{"msgtype":"text","text":{"content":"%s"}}' \
        "$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')")
    curl -sS -m 5 -H "Content-Type: application/json" -d "$payload" "$webhook" >/dev/null \
        && log_info "通知已发送" || log_warn "通知发送失败"
}

# 主入口模板:
# main() { ... }
# if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
