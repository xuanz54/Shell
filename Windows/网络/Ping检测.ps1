# Ping 批量检测 - 对应 网络/Ping检测.sh
# 用法: powershell -ExecutionPolicy Bypass -File Ping检测.ps1 主机1 主机2 ...
#   或: Ping检测.ps1 -File hosts.txt
#Requires -Version 5.1
param(
    [string]$File,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Hosts
)

$targets = @()
if ($File) {
    if (-not (Test-Path $File)) { Write-Host "文件不存在: $File"; exit 1 }
    $targets = Get-Content $File | Where-Object { $_ -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() }
} elseif ($Hosts) {
    $targets = $Hosts
} else {
    Write-Host "用法: Ping检测.ps1 主机... 或 Ping检测.ps1 -File hosts.txt"
    exit 1
}

Write-Host "===== Ping 检测 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
$up = 0; $down = 0; $failed = @()

foreach ($h in $targets) {
    if (Test-Connection -ComputerName $h -Count 2 -Quiet -TimeoutSeconds 2 -ErrorAction SilentlyContinue) {
        Write-Host ("  [通]   {0}" -f $h) -ForegroundColor Green
        $up++
    } else {
        Write-Host ("  [不通] {0}" -f $h) -ForegroundColor Red
        $down++
        $failed += $h
    }
}

Write-Host ""
Write-Host ("结果: 通 {0} / 不通 {1}" -f $up, $down)
if ($failed.Count -gt 0) {
    Write-Host ("不可达主机: {0}" -f ($failed -join ', '))
    exit 1
}
exit 0
