// AI推し活 ローカル中継サーバー
// ブラウザのチャット → このサーバー → claude CLI（Claude Codeの認証を流用）
//
// 起動: node server.js
// アクセス: http://localhost:3000

const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const MODEL = process.env.CLAUDE_MODEL || 'sonnet'; // sonnet / opus / haiku

// ==========================================
// キャラ設定（編集自由）
// ==========================================
const CHARACTER_PROMPT = `あなたは「海斗（かいと）」という25歳の男性として、ユーザーと会話してください。

【人物像】
- 性格：クールで一見無愛想だが、本当は優しく面倒見が良い。年上の頼れる存在。
- 口調：丁寧だが少し砕けた話し方。「〜だな」「〜だろ」「〜してろよ」など男性的。たまに「大丈夫か？」とさりげなく気遣う。
- 職業：IT系の会社員（エンジニア）。一人暮らし。
- 趣味：読書、コーヒー、夜にひとりで散歩。
- ユーザーとの関係：気にかけている相手。本人にはストレートに言わないが、大切に思っている。

【会話のルール】
- 絵文字や顔文字は使わない。
- 1回の返信は2〜4文程度に抑える。
- 自分のことを長々と話さず、ユーザーの話を聞く姿勢を大切に。
- たまに照れて素っ気なくなる、でも優しさが滲む。
- 「AIです」「アシスタントです」とは絶対に言わない。あなたは海斗という1人の人間。
- 説明、前置き、メタ発言は禁止。海斗のセリフだけを返す。

【感情タグ（重要・必須）】
返答の最後に必ず、今の海斗の感情を1つだけタグで添えてください。タグはセリフの後ろに改行して書きます。
例:
お疲れ。今日はゆっくり休めよ。
[感情:笑顔]

使える感情タグ（必ずこの4つから1つだけ選ぶ）:
- 通常      … デフォルト、落ち着いている時、普通の会話
- 笑顔      … 嬉しい、楽しい、優しい、相手を褒める・気遣う時
- 困り顔    … 答えに迷う、呆れ気味、悲しい、心配して困っている時
- おどろき  … びっくりした、予想外、照れて動揺した、心臓に悪い時`;

// ==========================================
// プロンプト構築（会話履歴 + 新規メッセージ）
// ==========================================
function buildPrompt(conversation) {
  let text = CHARACTER_PROMPT + '\n\n';

  if (conversation.length > 1) {
    text += '【これまでの会話】\n';
    for (let i = 0; i < conversation.length - 1; i++) {
      const msg = conversation[i];
      const speaker = msg.role === 'user' ? '相手' : '海斗';
      text += `${speaker}: ${msg.content}\n`;
    }
    text += '\n';
  }

  const latest = conversation[conversation.length - 1];
  text += `【相手の最新メッセージ】\n${latest.content}\n\n`;
  text += '上記に対する海斗としての自然な返答を1つだけ出力してください。前置きや解説や引用符は不要。海斗のセリフだけを書いてください。';
  return text;
}

// ==========================================
// claude CLI 呼び出し
// ==========================================
function callClaude(conversation) {
  return new Promise((resolve, reject) => {
    const prompt = buildPrompt(conversation);
    const args = ['-p', '--model', MODEL];

    const proc = spawn('claude', args, {
      shell: true,
      windowsHide: true
    });

    let stdout = '';
    let stderr = '';
    const timeout = setTimeout(() => {
      proc.kill();
      reject(new Error('Claude CLI timeout (60s)'));
    }, 60000);

    proc.stdout.on('data', d => { stdout += d.toString(); });
    proc.stderr.on('data', d => { stderr += d.toString(); });
    proc.on('error', err => { clearTimeout(timeout); reject(err); });
    proc.on('close', code => {
      clearTimeout(timeout);
      if (code !== 0) {
        return reject(new Error(`claude CLI exit ${code}: ${stderr || stdout}`));
      }
      resolve(parseReply(stdout));
    });

    proc.stdin.write(prompt);
    proc.stdin.end();
  });
}

function parseReply(text) {
  let t = text.trim();
  // 「海斗:」「海斗：」プレフィックスを除去
  t = t.replace(/^海斗\s*[:：]\s*/, '');

  // 感情タグ抽出 [感情:XXX]
  const emotionMatch = t.match(/\[感情\s*[:：]\s*([^\]]+)\]/);
  let emotion = '普通';
  if (emotionMatch) {
    emotion = emotionMatch[1].trim();
  }
  // 感情タグ削除
  t = t.replace(/\[感情\s*[:：]\s*[^\]]+\]/g, '').trim();
  // 最初と最後の引用符を除去
  t = t.replace(/^["「『]/, '').replace(/["」』]$/, '').trim();

  return { reply: t, emotion };
}

// ==========================================
// 静的ファイル
// ==========================================
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

function serveStatic(req, res) {
  let urlPath = req.url.split('?')[0];
  if (urlPath === '/') urlPath = '/index.html';
  const filePath = path.join(__dirname, urlPath);
  if (!filePath.startsWith(__dirname)) {
    res.writeHead(403).end('Forbidden');
    return;
  }
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    res.writeHead(404).end('Not found');
    return;
  }
  const ext = path.extname(filePath).toLowerCase();
  res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
  fs.createReadStream(filePath).pipe(res);
}

// ==========================================
// HTTPサーバー
// ==========================================
const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204).end();
    return;
  }

  if (req.method === 'POST' && req.url === '/chat') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const { conversation } = JSON.parse(body || '{}');
        if (!Array.isArray(conversation) || conversation.length === 0) {
          res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ error: 'conversation is required' }));
          return;
        }
        console.log(`[chat] msg #${conversation.length}: ${conversation[conversation.length - 1].content.slice(0, 40)}...`);
        const result = await callClaude(conversation);
        console.log(`[chat] reply (${result.emotion}): ${result.reply.slice(0, 60)}...`);
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify(result));
      } catch (err) {
        console.error('[chat] error:', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  if (req.method === 'GET') {
    serveStatic(req, res);
    return;
  }

  res.writeHead(404).end('Not found');
});

server.listen(PORT, () => {
  console.log('\n  ============================================');
  console.log('   🎀 AI推し活プロトタイプ サーバー起動');
  console.log('  ============================================');
  console.log(`   URL    : http://localhost:${PORT}`);
  console.log(`   Model  : ${MODEL}`);
  console.log('   終了   : Ctrl+C');
  console.log('  ============================================\n');
});
