# update_state.ps1
# state.json を更新する（投稿確定後に呼ぶ）
# 使い方:
#   pwsh.exe -File scripts/update_state.ps1 `
#     -KitchenId 01 `
#     -PostDate "2026-05-13" `
#     -FileNames @("TJA01779", "TJA01797")

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("01", "02", "03", "04")]
    [string]$KitchenId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$PostDate,

    [Parameter(Mandatory = $true)]
    [string[]]$FileNames
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$projectRoot = Split-Path -Parent $PSScriptRoot
$statePath = Join-Path $projectRoot "state.json"

if (-not (Test-Path $statePath)) {
    Write-Error "state.json が見つかりません: $statePath"
    exit 1
}

# バックアップ（直前の状態を1世代だけ残す）
$backupPath = "$statePath.bak"
Copy-Item -LiteralPath $statePath -Destination $backupPath -Force

$state = Get-Content -Raw -Encoding UTF8 -Path $statePath | ConvertFrom-Json

# 既存の used_files[KitchenId] を取得（無ければ空配列）
$existing = @()
if ($state.used_files -and $state.used_files.PSObject.Properties.Name -contains $KitchenId) {
    $existing = @($state.used_files.$KitchenId)
}

# 追加分のベース名（拡張子除去）
$additions = $FileNames | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_) }

# 重複排除して結合（大文字小文字を無視）
$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$merged = New-Object System.Collections.Generic.List[string]
foreach ($f in $existing) { if ($seen.Add($f)) { $merged.Add($f) } }
foreach ($f in $additions) { if ($seen.Add($f)) { $merged.Add($f) } }

# state を書き換え
$state.last_post_date = $PostDate
$state.last_kitchen = $KitchenId
$state.used_files.$KitchenId = $merged.ToArray()

# JSON 書き戻し（UTF-8 BOMなし）
$json = $state | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($statePath, $json, $utf8NoBom)

Write-Output "state.json を更新しました"
Write-Output "  last_post_date: $PostDate"
Write-Output "  last_kitchen:   $KitchenId"
Write-Output "  追加ファイル:   $($additions.Count) 件"
Write-Output "  累計使用枚数:   $($merged.Count) 件 (キッチン$KitchenId)"
Write-Output "  バックアップ:   $backupPath"
