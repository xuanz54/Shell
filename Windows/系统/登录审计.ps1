# 登录/安全审计 - 对应 系统/登录审计.ps1
# 查看最近登录、失败登录（安全事件 4625）、当前会话
# 用法: 以管理员运行效果最佳
#   powershell -ExecutionPolicy Bypass -File 登录审计.ps1
#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "===== 登录审计 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

Write-Host ""
Write-Host "-- 当前登录用户 --"
query user 2>$null
if (-not $?) { Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty UserName }

Write-Host ""
Write-Host "-- 最近登录成功 (事件 4624, 最近 20 条) --"
try {
    Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624 } -MaxEvents 20 -ErrorAction Stop |
        ForEach-Object {
            $xml = [xml]$_.ToXml()
            $user = ($xml.Event.EventData.Data | Where-Object Name -eq 'TargetUserName').'#text'
            $ip = ($xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress').'#text'
            [PSCustomObject]@{
                时间 = $_.TimeCreated
                用户 = $user
                来源IP = $ip
            }
        } | Format-Table -AutoSize
} catch {
    Write-Host "  无法读取安全日志（需要管理员权限）" -ForegroundColor Yellow
}

Write-Host "-- 最近登录失败 (事件 4625, 最近 20 条) --"
try {
    Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625 } -MaxEvents 20 -ErrorAction Stop |
        ForEach-Object {
            $xml = [xml]$_.ToXml()
            $user = ($xml.Event.EventData.Data | Where-Object Name -eq 'TargetUserName').'#text'
            $ip = ($xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress').'#text'
            [PSCustomObject]@{
                时间 = $_.TimeCreated
                用户 = $user
                来源IP = $ip
            }
        } | Format-Table -AutoSize
} catch {
    Write-Host "  无法读取安全日志（需要管理员权限）" -ForegroundColor Yellow
}

Write-Host "-- 失败登录 IP 统计 (事件 4625) --"
try {
    Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625 } -MaxEvents 500 |
        ForEach-Object {
            $xml = [xml]$_.ToXml()
            ($xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress').'#text'
        } |
        Where-Object { $_ -and $_ -ne '-' -and $_ -ne '::1' -and $_ -ne '127.0.0.1' } |
        Group-Object | Sort-Object Count -Descending | Select-Object -First 10 |
        ForEach-Object { Write-Host ("  {0,5}  {1}" -f $_.Count, $_.Name) }
} catch {
    Write-Host "  无数据或权限不足" -ForegroundColor Yellow
}
