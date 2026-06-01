# copy_photos.ps1
# 指定キッチンの指定ファイルを出力先フォルダにコピーする
# 使い方:
#   pwsh.exe -File scripts/copy_photos.ps1 `
#     -KitchenId 01 `
#     -FileNames @("TJA01779.jpg", "TJA01797.jpg") `
#     -DestinationFolder "C:\Users\event\OneDrive\デスクトップ\松岡カルーセル_2026-05-13"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("01", "02", "03", "04")]
    [string]$KitchenId,

    [Parameter(Mandatory = $true)]
    [string[]]$FileNames,

    [Parameter(Mandatory = $true)]
    [string]$DestinationFolder
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "config.json"

if (-not (Test-Path $configPath)) {
    Write-Error "config.json が見つかりません: $configPath"
    exit 1
}

$config = Get-Content -Raw -Encoding UTF8 -Path $configPath | ConvertFrom-Json

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

# 出力先フォルダ作成
if (-not (Test-Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
    Write-Output "出力先フォルダを作成しました: $DestinationFolder"
}

# キッチン配下の全画像をインデックス化（ベース名 → FullName）
$imageExts = @(".jpg", ".jpeg", ".png", ".heic", ".tif", ".tiff")
$index = @{}
Get-ChildItem -Path $kitchenFolder -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $imageExts -contains $_.Extension.ToLower() } |
    ForEach-Object {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        if (-not $index.ContainsKey($base)) {
            $index[$base] = $_.FullName
        }
    }

$copied = 0
$missing = @()

foreach ($name in $FileNames) {
    # 拡張子付きでも無しでも受け付ける
    $base = [System.IO.Path]::GetFileNameWithoutExtension($name)

    if (-not $index.ContainsKey($base)) {
        $missing += $name
        Write-Warning "見つからない: $name"
        continue
    }

    $src = $index[$base]
    $dstFile = Join-Path $DestinationFolder ([System.IO.Path]::GetFileName($src))

    # 順番が分かるように 01_ プレフィックスを付ける
    $orderIdx = [Array]::IndexOf($FileNames, $name) + 1
    $orderedName = "{0:D2}_{1}" -f $orderIdx, ([System.IO.Path]::GetFileName($src))
    $dstFile = Join-Path $DestinationFolder $orderedName

    Copy-Item -LiteralPath $src -Destination $dstFile -Force
    Write-Output "コピー完了: $orderedName"
    $copied++
}

Write-Output ""
Write-Output "----"
Write-Output "コピー件数: $copied / $($FileNames.Count)"
if ($missing.Count -gt 0) {
    Write-Output "見つからなかったファイル ($($missing.Count)):"
    $missing | ForEach-Object { Write-Output "  - $_" }
    exit 2
}
