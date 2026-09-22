# 查找大文件 - 对应 文件/查找大文件.sh
# 用法: powershell -ExecutionPolicy Bypass -File 查找大文件.ps1 [-Dir 目录] [-MB 100] [-Limit 20]
#Requires -Version 5.1
param(
    [string]$Dir = '.',
    [double]$MB = 100,
    [int]$Limit = 20
)

if (-not (Test-Path $Dir)) { Write-Host "目录不存在: $Dir"; exit 1 }

Write-Host ("===== 大文件查找: {0} (阈值 {1} MB) {2} =====" -f $Dir, $MB, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

Get-ChildItem -Path $Dir -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt $MB * 1MB } |
    Sort-Object Length -Descending |
    Select-Object -First $Limit |
    ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host ("{0,10} MB  {1}" -f $sizeMB, $_.FullName)
    }

Write-Host ""
Write-Host "----- 按目录汇总 Top 10 -----"
Get-ChildItem -Path $Dir -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $sum = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
    if ($sum) {
        [PSCustomObject]@{
            目录 = $_.FullName
            大小MB = [math]::Round($sum / 1MB, 1)
        }
    }
} | Sort-Object 大小MB -Descending | Select-Object -First 10 |
    Format-Table -AutoSize
