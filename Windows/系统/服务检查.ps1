# 服务状态检查 - 对应 系统/服务检查.sh
# 用法: powershell -ExecutionPolicy Bypass -File 服务检查.ps1 服务名1 服务名2 ...
#   默认检查: WinRM, Spooler, wuauserv
#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Services)

if (-not $Services -or $Services.Count -eq 0) {
    $Services = @('WinRM', 'Spooler', 'wuauserv')
}

Write-Host "===== 服务状态检查 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
$failed = @()

foreach ($svc in $Services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if (-not $s) {
        Write-Host ("  [不存在] {0}" -f $svc) -ForegroundColor Yellow
        $failed += $svc
        continue
    }
    if ($s.Status -eq 'Running') {
        Write-Host ("  [正常]   {0,-20} {1}" -f $s.Name, $s.Status) -ForegroundColor Green
    } else {
        Write-Host ("  [异常]   {0,-20} {1}" -f $s.Name, $s.Status) -ForegroundColor Red
        $failed += $svc
    }
    # 启动类型提示
    if ($s.StartType -eq 'Disabled' -and $s.Status -ne 'Running') {
        Write-Host ("           提示: {0} 已禁用启动" -f $s.Name) -ForegroundColor Yellow
    }
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host ("[警告] 以下服务异常: {0}" -f ($failed -join ', ')) -ForegroundColor Red
    exit 1
}
Write-Host ""
Write-Host "全部服务正常"
exit 0
