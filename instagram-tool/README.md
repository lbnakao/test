# 松岡製作所 Instagram カルーセル運用ツール

毎週水曜投稿のカルーセル投稿（画像5〜6枚＋ポエティックなキャプション）を Claude Code で半自動運用するためのプロジェクト。

## 使い方

1. **エクスプローラでこのフォルダ（`instagram-tool`）を開く**
2. **アドレスバーに `cmd` と打って Enter**（このフォルダでcmdを開く）
3. cmd で `claude` と打って Enter（Claude Code起動）
4. 下記の指示文（`PROMPT.md` の内容）をコピペして Enter

## ファイル構成

```
instagram-tool/
├── CLAUDE.md                # Claude Code に読ませる運用ルール
├── PROMPT.md                # 毎週 Claude Code に投げる指示文（コピペ用）
├── README.md                # この文書
├── config.json              # キッチン定義＋パス設定
├── state.json               # 使用済み画像・ローテーション状態（毎週更新）
├── scripts/
│   ├── copy_photos.ps1      # G:→デスクトップへ画像コピー
│   ├── list_unused.ps1      # 未使用画像一覧を取得
│   └── update_state.ps1     # state.json を更新
├── reference/               # キャプション文体の参考投稿
│   ├── post_DXg4mJ8gX5G.txt
│   └── post_DVedtvKgT8R.txt
└── archive/                 # 過去投稿のキャプション保管
```

## 前提条件
- KIOXIA (G:) SSD が接続されている
- PowerShell が使える（Windows標準）
- Claude Code がインストール済み

## ローテーション順
`01 → 03 → 02 → 04 → 01 ...`（03と04は同一人物なので連続させない）

## 初回セットアップ

`reference/` フォルダに、参考にしたい過去投稿のキャプション本文を以下のファイル名で保存してください：
- `reference/post_DXg4mJ8gX5G.txt`
- `reference/post_DVedtvKgT8R.txt`

これらが文体の見本になります。
