# 防火墙规则速查/添加 - Linux ufw 对应的 Windows 防火墙管理
# 用法:
#   防火墙规则.ps1 -Action List
#   防火墙规则.ps1 -Action Allow -Port 8080 -Name "允许8080"
#   防火墙规则.ps1 -Action Block -Port 4444 -Name "封禁4444"
# 需要管理员权限
#Requires -Version 5.1
param(
    [ValidateSet('List', 'Allow', 'Block')][string]$Action = 'List',
    [int]$Port,
    [string]$Name,
    [ValidateSet('TCP', 'UDP')][string]$Protocol = 'TCP'
)

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

switch ($Action) {
    'List' {
        Write-Host "===== 防火墙规则（入站，按端口过滤）====="
        Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction SilentlyContinue |
            Get-NetFirewallPortFilter -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPort -and $_.LocalPort -ne 'Any' } |
            Select-Object -First 40 @{ n = '协议'; e = { $_.Protocol } }, @{ n = '端口'; e = { $_.LocalPort -join ',' } } |
            Format-Table -AutoSize
        Write-Host "（完整规则见: 控制面板 -> Windows Defender 防火墙 -> 高级设置）"
    }
    'Allow' {
        if (-not (Test-Admin)) { Write-Host "需要管理员权限"; exit 1 }
        if (-not $Port) { Write-Host "请指定 -Port"; exit 1 }
        if (-not $Name) { $Name = "Allow-$Protocol-$Port" }
        New-NetFirewallRule -DisplayName $Name -Direction Inbound -Protocol $Protocol `
            -LocalPort $Port -Action Allow -ErrorAction Stop | Out-Null
        Write-Host "[已添加] 允许入站 $Protocol $Port ($Name)" -ForegroundColor Green
    }
    'Block' {
        if (-not (Test-Admin)) { Write-Host "需要管理员权限"; exit 1 }
        if (-not $Port) { Write-Host "请指定 -Port"; exit 1 }
        if (-not $Name) { $Name = "Block-$Protocol-$Port" }
        New-NetFirewallRule -DisplayName $Name -Direction Inbound -Protocol $Protocol `
            -LocalPort $Port -Action Block -ErrorAction Stop | Out-Null
        Write-Host "[已添加] 阻止入站 $Protocol $Port ($Name)" -ForegroundColor Green
    }
}
