# 端口连通性检测 - 对应 网络/端口检测.sh
# 用法: powershell -ExecutionPolicy Bypass -File 端口检测.ps1 -Host 目标 -Ports 22,80,443
#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][Alias('Target')][string]$HostName,
    [Parameter(Mandatory = $true)][int[]]$Ports,
    [int]$TimeoutMs = 2000
)

Write-Host ("===== 端口检测 {0} {1} =====" -f $HostName, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$failed = 0

foreach ($port in $Ports) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync($HostName, $port)
        if ($task.Wait($TimeoutMs) -and $client.Connected) {
            Write-Host ("  [开放] {0}:{1}" -f $HostName, $port) -ForegroundColor Green
        } else {
            Write-Host ("  [关闭/超时] {0}:{1}" -f $HostName, $port) -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host ("  [关闭/过滤] {0}:{1}" -f $HostName, $port) -ForegroundColor Red
        $failed++
    } finally {
        $client.Close()
    }
}

exit $(if ($failed -gt 0) { 1 } else { 0 })
