# 公网 IP 查询 - 对应 网络/公网IP查询.sh
# 用法: powershell -ExecutionPolicy Bypass -File 公网IP查询.ps1
#Requires -Version 5.1
$ErrorActionPreference = 'SilentlyContinue'

Write-Host "===== 网络出口信息 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

Write-Host ""
Write-Host "-- 公网 IP --"
$ip = $null
try { $ip = (Invoke-RestMethod -Uri 'https://ifconfig.me/ip' -TimeoutSec 5).Trim() } catch {}
if (-not $ip) {
    try { $ip = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5).Trim() } catch {}
}
if ($ip) { Write-Host $ip } else { Write-Host "获取失败" }

if ($ip) {
    Write-Host ""
    Write-Host "-- IP 详情 --"
    try {
        $info = Invoke-RestMethod -Uri "https://ipinfo.io/$ip/json" -TimeoutSec 5
        Write-Host ("IP:      {0}" -f $info.ip)
        Write-Host ("主机名:   {0}" -f $info.hostname)
        Write-Host ("位置:     {0}, {1}, {2}" -f $info.city, $info.region, $info.country)
        Write-Host ("坐标:     {0}" -f $info.loc)
        Write-Host ("运营商:   {0}" -f $info.org)
    } catch { Write-Host "详情获取失败" }
}

Write-Host ""
Write-Host "-- DNS 服务器 --"
Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.ServerAddresses } |
    ForEach-Object { Write-Host ("  {0}: {1}" -f $_.InterfaceAlias, ($_.ServerAddresses -join ', ')) }

Write-Host ""
Write-Host "-- 本地接口 --"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | ForEach-Object {
    Write-Host ("  {0,-15} {1}" -f $_.IPAddress, $_.InterfaceAlias)
}
