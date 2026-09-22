# 日志轮转（压缩旧日志） - 对应 运维/日志轮转.sh
# 用法: powershell -ExecutionPolicy Bypass -File 日志轮转.ps1 [-Dir 日志目录] [-CompressDays 7] [-DeleteDays 30]
#Requires -Version 5.1
param(
    [string]$Dir = "C:\Logs",
    [int]$CompressDays = 7,
    [int]$DeleteDays = 30
)

if (-not (Test-Path $Dir)) {
    Write-Host "目录不存在: $Dir (可手动指定 -Dir)"
    exit 1
}

Write-Host ("===== 日志轮转: {0} (压缩>{1}天, 删除>{2}天) =====" -f $Dir, $CompressDays, $DeleteDays)

$cutoffCompress = (Get-Date).AddDays(-$CompressDays)
$cutoffDelete = (Get-Date).AddDays(-$DeleteDays)

# 压缩旧 .log（跳过已压缩）
Get-ChildItem -Path $Dir -Filter *.log -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoffCompress } |
    ForEach-Object {
        $zip = "$($_.FullName).$(Get-Date -Format yyyyMMdd).zip"
        try {
            Compress-Archive -Path $_.FullName -DestinationPath $zip -Force
            Remove-Item $_.FullName -Force
            Write-Host "已压缩: $($_.Name) -> $(Split-Path $zip -Leaf)" -ForegroundColor Green
        } catch {
            Write-Host "压缩失败: $($_.Name) - $_" -ForegroundColor Yellow
        }
    }

# 删除过期压缩包
Get-ChildItem -Path $Dir -Include *.zip, *.gz, *.7z -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoffDelete } |
    ForEach-Object {
        Write-Host "已删除: $($_.Name)" -ForegroundColor Green
        Remove-Item $_.FullName -Force
    }

Write-Host ""
Write-Host "当前目录占用:"
$sum = (Get-ChildItem $Dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
if ($null -eq $sum) { $sum = 0 }
Write-Host ("  {0} : {1} MB" -f $Dir, [math]::Round($sum / 1MB, 1))
