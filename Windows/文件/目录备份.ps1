# 目录备份（增量 xcopy/robocopy） - 对应 备份/目录备份.sh
# 用法: powershell -ExecutionPolicy Bypass -File 目录备份.ps1 -Source 源 -Dest 备份目录 [-Keep 7]
#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Dest,
    [int]$Keep = 7
)

if (-not (Test-Path $Source)) { Write-Host "源不存在: $Source"; exit 1 }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$base = Split-Path $Source -Leaf
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$zipName = "{0}_{1}.zip" -f $base, $stamp
$zipPath = Join-Path $Dest $zipName
$logPath = Join-Path $Dest "备份日志.txt"

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Write-Host $line
    Add-Content -Path $logPath -Value $line
}

Log "开始备份: $Source -> $zipPath"

try {
    # 优先 robocopy 到临时目录再压缩；简单场景直接 Compress-Archive
    Compress-Archive -Path $Source -DestinationPath $zipPath -Force -ErrorAction Stop
    $size = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Log "备份完成: $zipPath ($size MB)"
} catch {
    Log "备份失败: $_"
    exit 1
}

# 轮转：保留最近 Keep 份
$old = Get-ChildItem -Path $Dest -Filter "${base}_*.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -Skip $Keep

foreach ($f in $old) {
    Remove-Item $f.FullName -Force
    Log "删除旧备份: $($f.Name)"
}

Log "当前备份列表:"
Get-ChildItem -Path $Dest -Filter "${base}_*.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $Keep |
    ForEach-Object { Log "  $($_.Name)" }
