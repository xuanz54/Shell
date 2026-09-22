# 内存监控 - 对应 系统/内存监控.sh
# 用法: powershell -ExecutionPolicy Bypass -File 内存监控.ps1 [阈值百分比]
#Requires -Version 5.1
param([int]$Threshold = 80)

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

$totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory * 1KB / 1GB, 2)
$usedGB = [math]::Round($totalGB - $freeGB, 2)
$usedPct = if ($totalGB -gt 0) { [math]::Round($usedGB / $totalGB * 100) } else { 0 }

Write-Host "===== 内存使用 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
Write-Host "总内存: $totalGB GB"
Write-Host "已用:   $usedGB GB ($usedPct%)"
Write-Host "可用:   $freeGB GB"
Write-Host ""
Write-Host "----- 内存占用 Top 10 (工作集) -----"
Write-Host ("{0,-8} {1,-30} {2,10} {3,8}" -f "PID", "进程名", "内存(MB)", "占比%")

Get-Process | Sort-Object WS -Descending | Select-Object -First 10 | ForEach-Object {
    $mb = [math]::Round($_.WS / 1MB, 1)
    $pct = if ($totalGB -gt 0) { [math]::Round($_.WS / ($totalGB * 1GB) * 100, 1) } else { 0 }
    Write-Host ("{0,-8} {1,-30} {2,10} {3,8}" -f $_.Id, $_.ProcessName, $mb, $pct)
}

if ($usedPct -ge $Threshold) {
    Write-Host ""
    Write-Host "[警告] 内存占用超过阈值 $Threshold%!" -ForegroundColor Red
    exit 1
}
exit 0
