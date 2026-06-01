# list_unused.ps1
# 指定キッチンの未使用画像一覧を取得する
# 使い方: pwsh.exe -File scripts/list_unused.ps1 -KitchenId 01

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("01", "02", "03", "04")]
    [string]$KitchenId
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$projectRoot = Split-Path -Parent $PSScriptRoot

$configPath = Join-Path $projectRoot "config.json"
$statePath  = Join-Path $projectRoot "state.json"

if (-not (Test-Path $configPath)) {
    Write-Error "config.json が見つかりません: $configPath"
    exit 1
}
if (-not (Test-Path $statePath)) {
    Write-Error "state.json が見つかりません: $statePath"
    exit 1
}

$config = Get-Content -Raw -Encoding UTF8 -Path $configPath | ConvertFrom-Json
$state  = Get-Content -Raw -Encoding UTF8 -Path $statePath  | ConvertFrom-Json

$kitchen = $config.kitchens.$KitchenId
if (-not $kitchen) {
    Write-Error "config.json にキッチンID '$KitchenId' の定義がありません"
    exit 1
}

$kitchenFolder = Join-Path $config.kitchen_root $kitchen.folder

if (-not (Test-Path $kitchenFolder)) {
    Write-Error "キッチンフォルダが見つかりません: $kitchenFolder`nKIOXIA SSD (G:) が接続されているか確認してください。"
    exit 1
}

# 使用済みファイル名（拡張子なし）の一覧
$used = @()
if ($state.used_files -and $state.used_files.PSObject.Properties.Name -contains $KitchenId) {
    $used = @($state.used_files.$KitchenId)
}
$usedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($u in $used) { [void]$usedSet.Add($u) }

# キッチンフォルダ配下の画像ファイル（再帰）
$imageExts = @(".jpg", ".jpeg", ".png", ".heic", ".tif", ".tiff")
$allFiles = Get-ChildItem -Path $kitchenFolder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $imageExts -contains $_.Extension.ToLower() }

# ベース名（拡張子なし）の重複排除
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($f in $allFiles) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    if ($usedSet.Contains($base)) { continue }
    if ($seen.Add($base)) {
        Write-Output $base
    }
}
