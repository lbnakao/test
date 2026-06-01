# Claude Code 応答待ち通知スクリプト
# 中央ポップアップのみ（最前面・30秒で自動消失またはOKクリックで閉じる）

try {
    Start-Process powershell -ArgumentList '-NoProfile','-WindowStyle','Hidden','-Command',"(New-Object -ComObject WScript.Shell).Popup('Claude Code が応答を待っています。PCに戻ってきてください。',30,'松岡製作所インスタツール',0x40)"
} catch {}