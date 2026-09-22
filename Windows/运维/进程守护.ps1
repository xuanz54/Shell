# 服务/进程守护（自动重启） - 对应 系统/进程守护.sh
# 指定进程名，退出后自动重启
# 用法: powershell -ExecutionPolicy Bypass -File 进程守护.ps1 -ProcessName 进程名 [-MaxRestart 100] [-Interval 3]
#   也可: 进程守护.ps1 -ProcessName notepad -ArgumentList "-Option"
#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$ProcessName,
    [string[]]$ArgumentList = @(),
    [int]$MaxRestart = 100,
    [int]$Interval = 3
)

$restarts = 0
Write-Host ("===== 进程守护启动: {0} {1} =====" -f $ProcessName, ($ArgumentList -join ' '))

while ($restarts -lt $MaxRestart) {
    Write-Host ("[{0}] 启动: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ProcessName)
    try {
        if ($ArgumentList.Count -gt 0) {
            $p = Start-Process -FilePath $ProcessName -ArgumentList $ArgumentList -PassThru
        } else {
            $p = Start-Process -FilePath $ProcessName -PassThru
        }
        $p.WaitForExit()
        $code = $p.ExitCode
    } catch {
        Write-Host ("启动失败: {0}" -f $_) -ForegroundColor Red
        $code = -1
    }

    $restarts++
    Write-Host ("[{0}] 进程退出 code={1}，第 {2} 次重启（{3}s 后）" -f `
        (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $code, $restarts, $Interval) -ForegroundColor Yellow
    Start-Sleep -Seconds $Interval
}

Write-Host "[警告] 已达最大重启次数 $MaxRestart" -ForegroundColor Red
exit 1
