# 磁盘使用率检查 - 对应 系统/磁盘检查.sh
# 用法: powershell -ExecutionPolicy Bypass -File 磁盘检查.ps1 [阈值百分比]
#Requires -Version 5.1
param([int]$Threshold = 80)

$exitCode = 0
Write-Host "===== 磁盘使用率检查 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') (阈值 $Threshold%) ====="
Write-Host ("{0,-10} {1,10} {2,10} {3,10} {4,6}" -f "驱动器", "总计(GB)", "已用(GB)", "可用(GB)", "使用率")

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [math]::Round($_.Size / 1GB, 2)
    $free = [math]::Round($_.FreeSpace / 1GB, 2)
    $used = [math]::Round($total - $free, 2)
    $pct = if ($total -gt 0) { [math]::Round($used / $total * 100) } else { 0 }
    Write-Host ("{0,-10} {1,10} {2,10} {3,10} {4,5}%" -f $_.DeviceID, $total, $used, $free, $pct)
    if ($pct -ge $Threshold) {
        Write-Host ("[警告] {0} 使用率 {1}% 超过阈值 {2}%" -f $_.DeviceID, $pct, $Threshold) -ForegroundColor Red
        $script:exitCode = 1
    }
}

exit $exitCode
