# 系统信息 - 对应 系统/系统信息.sh
# 用法: powershell -ExecutionPolicy Bypass -File 系统信息.ps1
#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "========== 系统信息 =========="
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

Write-Host "主机名:   $env:COMPUTERNAME"
Write-Host "系统:     $($os.Caption) $($os.Version)"
Write-Host "架构:     $($os.OSArchitecture)"
Write-Host "安装日期: $($os.InstallDate)"
Write-Host "运行时间: $((New-TimeSpan -Start $os.LastBootUpTime).ToString())"
Write-Host "用户:     $($cs.UserName)"

Write-Host ""
Write-Host "========== CPU =========="
Write-Host "型号:     $($cpu.Name.Trim())"
Write-Host "核心/线程: $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
Write-Host "当前频率: $($cpu.CurrentClockSpeed) MHz"

Write-Host ""
Write-Host "========== 内存 =========="
$totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory * 1KB / 1GB, 2)
$usedGB = [math]::Round($totalGB - $freeGB, 2)
$usedPct = if ($totalGB -gt 0) { [math]::Round($usedGB / $totalGB * 100, 1) } else { 0 }
Write-Host "总内存:   $totalGB GB"
Write-Host "已用:     $usedGB GB ($usedPct%)"
Write-Host "可用:     $freeGB GB"

Write-Host ""
Write-Host "========== 磁盘 =========="
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [math]::Round($_.Size / 1GB, 2)
    $free = [math]::Round($_.FreeSpace / 1GB, 2)
    $used = [math]::Round($total - $free, 2)
    $pct = if ($total -gt 0) { [math]::Round($used / $total * 100) } else { 0 }
    Write-Host ("{0,-4} 总计 {1,8} GB  已用 {2,8} GB  可用 {3,8} GB  {4}%" -f $_.DeviceID, $total, $used, $free, $pct)
}

Write-Host ""
Write-Host "========== 网络 =========="
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | ForEach-Object {
    Write-Host ("{0,-12} {1}" -f $_.InterfaceAlias, $_.IPAddress)
}
