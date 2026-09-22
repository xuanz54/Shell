# 文件权限/ACL 查看 - 对应 文件/权限审计.sh（Windows ACL 模型）
# 用法: powershell -ExecutionPolicy Bypass -File 权限查看.ps1 [-Path 路径]
# 说明: Windows ACL 与 Unix rwx 不同，仅查看继承与访问规则
#Requires -Version 5.1
param([string]$Path = (Get-Location).Path)

if (-not (Test-Path $Path)) { Write-Host "路径不存在: $Path"; exit 1 }

Write-Host "===== 权限/ACL 查看: $Path ====="
Write-Host ""

$items = @()
if (Test-Path $Path -PathType Container) {
    $items = Get-ChildItem $Path -Force -ErrorAction SilentlyContinue | Select-Object -First 50
} else {
    $items = @(Get-Item $Path -Force)
}

foreach ($item in $items) {
    try {
        $acl = Get-Acl -LiteralPath $item.FullName
        Write-Host ("-- {0} --" -f $item.Name)
        Write-Host ("   属主: {0}" -f $acl.Owner)
        Write-Host ("   组:   {0}" -f $acl.Group)
        foreach ($rule in $acl.Access) {
            $inherit = if ($rule.IsInherited) { "继承" } else { "显式" }
            Write-Host ("   [{0}] {1} -> {2}" -f $inherit, $rule.IdentityReference, $rule.FileSystemRights)
        }
        Write-Host ""
    } catch {
        Write-Host ("-- {0}: 读取 ACL 失败 --" -f $item.Name) -ForegroundColor Yellow
    }
}

Write-Host "提示: 修改 ACL 用 Set-Acl/icacls，例如:"
Write-Host "  icacls `"$Path`" /grant 用户名:(OI)(CI)F /T"
Write-Host "  icacls `"$Path`" /inheritance:r /grant:r 用户名:R"
