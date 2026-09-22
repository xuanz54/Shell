# 进程监控 - 对应 系统/CPU监控.sh 与 系统/进程守护.ps1 场景
# 用法: powershell -ExecutionPolicy Bypass -File 进程监控.ps1 [间隔秒] [次数, 0=无限]
#Requires -Version 5.1
param(
    [int]$Interval = 2,
    [int]$Count = 0
)

$i = 0
while ($true) {
    Clear-Host
    Write-Host "===== 进程监控 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

    $cpuTime1 = @{}
    Get-Process | ForEach-Object { $cpuTime1[$_.Id] = $_.CPU }

    # 系统级 CPU
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
    Write-Host ("总 CPU: {0}% used" -f [math]::Round($cpu.Average, 1))
    Write-Host ""

    Write-Host ("{0,-8} {1,-28} {2,8} {3,10} {4,10}" -f "PID", "进程名", "CPU%", "内存(MB)", "启动时间")
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
        $start = try { $_.StartTime.ToString('MM-dd HH:mm') } catch { '-' }
        Write-Host ("{0,-8} {1,-28} {2,8} {3,10} {4,10}" -f `
            $_.Id,
        ($_.ProcessName.Substring(0, [Math]::Min(27, $_.ProcessName.Length))),
        [math]::Round($_.CPU, 1),
        [math]::Round($_.WS / 1MB, 1),
        $start)
    }

    $i++
    if ($Count -gt 0 -and $i -ge $Count) { break }
    Start-Sleep -Seconds $Interval
}
