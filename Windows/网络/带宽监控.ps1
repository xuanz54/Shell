# 网络带宽监控 - 对应 网络/带宽监控.sh
# 读取网卡累计字节数计算速率（PowerShell 5.1 兼容）
# 用法: powershell -ExecutionPolicy Bypass -File 带宽监控.ps1 [-接口名] [-间隔秒]
#Requires -Version 5.1
param(
    [string]$Interface,
    [int]$Interval = 2
)

if (-not $Interface) {
    $Interface = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
}
if (-not $Interface) { Write-Host "未找到活动网卡"; exit 1 }

Write-Host ("===== 带宽监控: {0} (间隔 {1}s, Ctrl+C 退出) =====" -f $Interface, $Interval)
Write-Host ("{0,-22} {1,14} {2,14}" -f "时间", "接收速率", "发送速率")

function Get-Bytes($name) {
    $s = Get-NetAdapterStatistics -Name $name -ErrorAction SilentlyContinue
    if ($s) { return @{ Rx = $s.ReceivedBytes; Tx = $s.SentBytes } }
    return $null
}

function Format-Rate($bytes) {
    $r = $bytes / $Interval
    if ($r -gt 1GB) { return "{0:N2} GB/s" -f ($r / 1GB) }
    if ($r -gt 1MB) { return "{0:N2} MB/s" -f ($r / 1MB) }
    if ($r -gt 1KB) { return "{0:N2} KB/s" -f ($r / 1KB) }
    return "{0:N0} B/s" -f $r
}

$prev = Get-Bytes $Interface
if (-not $prev) { Write-Host "无法读取网卡统计"; exit 1 }

try {
    while ($true) {
        Start-Sleep -Seconds $Interval
        $cur = Get-Bytes $Interface
        if (-not $cur) { break }
        $drx = $cur.Rx - $prev.Rx
        $dtx = $cur.Tx - $prev.Tx
        $prev = $cur
        Write-Host ("{0,-22} {1,14} {2,14}" -f `
            (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),
        (Format-Rate $drx),
        (Format-Rate $dtx))
    }
} catch {
    Write-Host "监控停止"
}
