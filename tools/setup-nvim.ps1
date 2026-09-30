[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$localAppData = [Environment]::GetFolderPath('LocalApplicationData')
if ([string]::IsNullOrWhiteSpace($localAppData)) {
    throw 'LOCALAPPDATA could not be resolved.'
}
$target = [IO.Path]::GetFullPath((Join-Path $localAppData 'nvim'))
$expectedParent = [IO.Path]::GetFullPath($localAppData).TrimEnd('\') + '\'
if (-not $target.StartsWith($expectedParent, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing an nvim target outside LOCALAPPDATA: $target"
}

if (Test-Path -LiteralPath $target) {
    $item = Get-Item -LiteralPath $target -Force
    if (-not $item.PSIsContainer) {
        throw "Neovim config target exists but is not a directory: $target"
    }

    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        $resolved = [IO.Path]::GetFullPath([string]$item.Target)
        if (-not [string]::Equals($resolved, $repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Neovim config junction points somewhere else: $target -> $resolved"
        }
        Write-Host "Neovim config junction: OK ($target -> $repoRoot)"
        return
    }

    $children = @(Get-ChildItem -LiteralPath $target -Force)
    if ($children.Count -ne 0) {
        throw "Refusing to replace a non-empty Neovim config directory: $target"
    }
    if ($ValidateOnly) {
        Write-Host "Neovim config target is an empty directory and can be linked: $target"
        return
    }
    Remove-Item -LiteralPath $target -Force
}
elseif ($ValidateOnly) {
    Write-Host "Neovim config target is absent and can be linked: $target"
    return
}

[void](New-Item -ItemType Junction -Path $target -Target $repoRoot)
$createdItem = Get-Item -LiteralPath $target -Force
$resolvedTarget = [IO.Path]::GetFullPath([string]$createdItem.Target)
if (-not [string]::Equals($resolvedTarget, $repoRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Created junction did not resolve to the checkout: $target -> $resolvedTarget"
}
Write-Host "Neovim config junction: applied ($target -> $repoRoot)"
