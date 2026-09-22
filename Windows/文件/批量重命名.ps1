# 批量重命名 - 对应 文件/批量重命名.ps1
# 用法:
#   批量重命名.ps1 -Dir 目录 -Prefix 前缀          # 加前缀
#   批量重命名.ps1 -Dir 目录 -Replace "旧:新"       # 替换字符串
#   批量重命名.ps1 -Dir 目录 -Sequence "img"        # 序号命名 img_001.jpg
#   确认无误后加 -Apply 实际执行（默认预览）
#Requires -Version 5.1
param(
    [string]$Dir = '.',
    [string]$Prefix,
    [string]$Replace,
    [string]$Sequence,
    [switch]$Apply
)

if (-not (Test-Path $Dir -PathType Container)) { Write-Host "目录不存在: $Dir"; exit 1 }

$mode = @()
if ($Prefix)   { $mode += 'prefix' }
if ($Replace)  { $mode += 'replace' }
if ($Sequence) { $mode += 'seq' }
if ($mode.Count -ne 1) {
    Write-Host "请指定且仅指定一种模式: -Prefix / -Replace / -Sequence"
    exit 1
}

$files = Get-ChildItem -Path $Dir -File
$i = 0

foreach ($f in $files) {
    $i++
    $newName = $f.Name

    switch ($mode[0]) {
        'prefix' { $newName = "${Prefix}_$($f.Name)" }
        'replace' {
            $parts = $Replace -split ':', 2
            if ($parts.Count -lt 2) { Write-Host "-Replace 格式: 旧字符串:新字符串"; exit 1 }
            $newName = $f.Name.Replace($parts[0], $parts[1])
        }
        'seq' {
            $ext = if ($f.Extension) { $f.Extension } else { '' }
            $newName = "{0}_{1:d3}{2}" -f $Sequence, $i, $ext
        }
    }

    if ($newName -eq $f.Name) { continue }

    $src = Join-Path $Dir $f.Name
    $dst = Join-Path $Dir $newName

    if (-not $Apply) {
        Write-Host ("[预览] {0}  ->  {1}" -f $f.Name, $newName)
    } else {
        if (Test-Path $dst) {
            Write-Host ("[跳过] 目标已存在: {0}" -f $newName) -ForegroundColor Yellow
        } else {
            Rename-Item -LiteralPath $src -NewName $newName
            Write-Host ("[重命名] {0}  ->  {1}" -f $f.Name, $newName) -ForegroundColor Green
        }
    }
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "以上为预览，确认无误后加 -Apply 执行"
}
