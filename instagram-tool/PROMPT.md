# Claude Code への指示文（コピペ用）

下記の `=== ここから ===` から `=== ここまで ===` の間をコピーして、Claude Code に貼り付けて Enter してください。

---

=== ここから ===

あなたは松岡製作所Instagramカルーセル投稿の運用担当です。
このプロジェクト直下の `CLAUDE.md` を最優先のルールブックとして読み込み、その手順に厳密に従ってください。

「今週の作業」：今週分のカルーセル投稿（画像5〜6枚＋キャプション）を準備してください。

具体的な進め方：

1. `state.json` を読んで `last_kitchen` を確認。`config.json` の `rotation_order` を参照して**今週使うキッチンID**を決定する（`01 → 03 → 02 → 04 → 01...` の順）。

2. PowerShell で未使用画像一覧を取得：
   ```
   powershell -ExecutionPolicy Bypass -File scripts/list_unused.ps1 -KitchenId <今週のID>
   ```

3. 出力された未使用ファイル名からファイル番号が散らばるように 10〜15枚を選んで Read tool で画像を確認、各画像を以下のシーンに分類：
   - 引き（キッチン全景）
   - 食事（朝食・コーヒー・食卓）
   - 質感（ステンレス天板・シンクのアップ）
   - 調理準備（コンロ前・食材を扱う）
   - 収納（扉を引き出す・開ける）
   - 清掃（拭く・磨く）

4. 5シーン以上をカバーし、5〜6枚を選定。1枚目は「引き」推奨。視覚的に物語が繋がる順に並べる。

5. 選定結果を仲尾さんに**表形式で提示**し（順番／ファイル名／シーン名）、了承を得る。

6. 了承後、`reference/post_DXg4mJ8gX5G.txt` と `reference/post_DVedtvKgT8R.txt` を読んで文体を確認し、今週のフードでキャプションを生成。構成は必ず：
   - 「フード」見出し
   - 日本語ポエティック本文（5〜8行）
   - 英訳タイトル／英訳本文
   - ハッシュタグ5個（`#松岡製作所` 必須）

   トーン：制作会社的な機能訴求はしない。暮らしの所作・素材の手触り・光と陰影を主役に。ステンレスの清潔感・オーダーの自由度・ヒヤリハットインスペレーション付与に**軽く**触れる程度。

7. 今日の日付で出力先パスを生成：
   ```
   C:\Users\event\OneDrive\デスクトップ\松岡カルーセル_YYYY-MM-DD
   ```

8. PowerShellで画像コピー：
   ```
   powershell -ExecutionPolicy Bypass -File scripts/copy_photos.ps1 `
     -KitchenId "<今週のID>" `
     -FileNames @("TJA0XXXX.jpg","TJA0YYYY.jpg",...) `
     -DestinationFolder "C:\Users\event\OneDrive\デスクトップ\松岡カルーセル_YYYY-MM-DD"
   ```

9. キャプション本文＋投稿メタ情報（投稿日・キッチン名・選定シーン6つ）を `{出力先}\caption.txt` に書き込み（UTF-8）。

10. state.json を更新：
    ```
    powershell -ExecutionPolicy Bypass -File scripts/update_state.ps1 `
      -KitchenId "<今週のID>" `
      -PostDate "YYYY-MM-DD" `
      -FileNames @("TJA0XXXX","TJA0YYYY",...)
    ```

11. アーカイブ：`archive/YYYY-MM-DD_<キッチン名>/` フォルダを作って caption.txt をコピー、選定リスト（manifest.txt）も保存。

12. 最後に「準備完了、デスクトップの `松岡カルーセル_YYYY-MM-DD` フォルダを確認してください」と仲尾さんに報告。

注意事項：
- 03と04は同一人物、ローテーションで必ず間に他キッチンを挟むこと
- 撮影は同じシーン（コーヒーを淹れる等）が複数バーストで存在するため、シーン分類時にファイル番号が近いものは同一シーンとして扱う
- 仲尾さんから「やり直して」と言われたら、選定からやり直し（state.jsonへの記録は確定後のみ）

=== ここまで ===

---

## 補足

- 毎週水曜の朝、このプロジェクトフォルダで `claude` を起動 → 上記プロンプトで完結します
- 文体や選定基準を変えたい時は `CLAUDE.md` を直接編集すれば次回から反映されます
- 全キッチンの画像が枯渇したら state.json の `used_files` を空配列に戻せばリセットされます
