# 系统清理 - 对应 系统/系统清理.sh
# 清理临时文件、Windows 更新缓存、回收站、缩略图缓存
# 用法: powershell -ExecutionPolicy Bypass -File 系统清理.ps1 [-Yes]
# 需要管理员权限执行部分操作
#Requires -Version 5.1
param([switch]$Yes)

function Get-SizeMB($path) {
    if (-not (Test-Path $path)) { return 0 }
    try {
        $sum = (Get-ChildItem $path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum).Sum
        if ($null -eq $sum) { return 0 }
        return [math]::Round($sum / 1MB, 1)
    } catch { return 0 }
}

Write-Host "===== 系统清理 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====="

$targets = @(
    $env:TEMP,
    "C:\Windows\Temp",
    "C:\Windows\SoftwareDistribution\Download",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
)

foreach ($t in $targets) {
    if (-not (Test-Path $t)) { continue }
    $before = Get-SizeMB $t
    if (-not $Yes) {
        $ans = Read-Host "清理 $t (约 $before MB)? [y/N]"
        if ($ans -notmatch '^[Yy]') { Write-Host "  跳过"; continue }
    } else {
        Write-Host ">>> 清理 $t (约 $before MB)"
    }
    Get-ChildItem $t -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    $after = Get-SizeMB $t
    Write-Host ("  释放约 {0} MB" -f [math]::Round($before - $after, 1)) -ForegroundColor Green
}

# 回收站
if (-not $Yes) {
    $ans = Read-Host "清空回收站? [y/N]"
    if ($ans -match '^[Yy]') { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
} else {
    Write-Host ">>> 清空回收站"
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "清理完成。磁盘状态:"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $total = [math]::Round($_.Size / 1GB, 1)
    $free = [math]::Round($_.FreeSpace / 1GB, 1)
    Write-Host ("  {0} 总计 {1} GB, 可用 {2} GB" -f $_.DeviceID, $total, $free)
}
