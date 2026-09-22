# Windows 系统一键巡检报告 - 对应 日志/巡检报告.sh
# 用法: powershell -ExecutionPolicy Bypass -File 巡检报告.ps1 [-OutFile 报告路径]
#Requires -Version 5.1
param([string]$OutFile = "$env:TEMP\巡检报告_$(Get-Date -Format yyyyMMdd).txt")

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$sb = New-Object System.Text.StringBuilder

function Add-Line($s) { [void]$sb.AppendLine($s); Write-Host $s }

Add-Line "===== 服务器巡检报告 - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="
Add-Line ""
Add-Line "-- 系统 --"
Add-Line ("系统:     {0}" -f $os.Caption)
Add-Line ("运行时间: {0}" -f (New-TimeSpan -Start $os.LastBootUpTime).ToString())

Add-Line ""
Add-Line "-- 内存 --"
$totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory * 1KB / 1GB, 1)
Add-Line ("总计 {0} GB, 可用 {1} GB, 已用 {2}%" -f $totalGB, $freeGB, [math]::Round(($totalGB - $freeGB) / $totalGB * 100))

Add-Line ""
Add-Line "-- 磁盘 --"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [math]::Round($_.Size / 1GB, 1)
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    $pct = if ($total -gt 0) { [math]::Round(($total - $free) / $total * 100) } else { 0 }
    $mark = if ($pct -gt 85) { " [警告]" } else { "" }
    Add-Line ("{0} 总计 {1} GB, 可用 {2} GB, 使用 {3}%{4}" -f $_.DeviceID, $total, $free, $pct, $mark)
}

Add-Line ""
Add-Line "-- 异常/停止的关键服务 --"
$critical = 'WinRM', 'Tcpip', 'Dnscache', 'EventLog', 'LanmanServer'
foreach ($n in $critical) {
    $s = Get-Service -Name $n -ErrorAction SilentlyContinue
    if ($s -and $s.Status -ne 'Running') {
        Add-Line ("  [异常] {0} = {1}" -f $s.Name, $s.Status)
    }
}
Add-Line "  (无输出表示关键服务正常)"

Add-Line ""
Add-Line "-- CPU Top 5 --"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
    Add-Line ("  {0,-30} CPU={1}s MEM={2}MB" -f $_.ProcessName, [math]::Round($_.CPU, 1), [math]::Round($_.WS / 1MB))
}

Add-Line ""
Add-Line "-- 失败 Windows Update 服务状态 --"
$wuauserv = Get-Service wuauserv -ErrorAction SilentlyContinue
Add-Line ("  wuauserv = {0}" -f $(if ($wuauserv) { $wuauserv.Status } else { 'N/A' }))

$sb.ToString() | Set-Content -Path $OutFile -Encoding UTF8
Write-Host ""
Write-Host "报告已保存: $OutFile" -ForegroundColor Green
