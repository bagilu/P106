// P106AnalyzeInput Supabase Edge Function
// 用途：接收 source_text / source_url，回傳 P106 欄位歸類建議。
// 部署方式：Supabase Dashboard > Edge Functions > Create function，名稱請用 P106AnalyzeInput，手動貼上本檔內容。
// 需要 Secrets：OPENAI_API_KEY。可選：OPENAI_MODEL，預設 gpt-4.1-mini。

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  try {
    const { source_text = '', source_url = '' } = await req.json();
    let fetchedText = '';

    if (source_url && /^https?:\/\//i.test(source_url)) {
      fetchedText = await tryFetchReadableText(source_url);
    }

    const inputText = [source_text, fetchedText].filter(Boolean).join('\n\n').slice(0, 12000);
    if (!inputText && !source_url) return json({ error: '請提供文字或網址。' }, 400);

    const apiKey = Deno.env.get('OPENAI_API_KEY');
    if (!apiKey) return json({ error: '尚未設定 OPENAI_API_KEY。' }, 500);

    const model = Deno.env.get('OPENAI_MODEL') || 'gpt-4.1-mini';
    const prompt = buildPrompt(inputText, source_url);

    const aiRes = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      body: JSON.stringify({
        model,
        temperature: 0.2,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: '你是資料整理助理。只輸出合法 JSON，不要使用 Markdown。所有欄位以繁體中文輸出。無法判斷的欄位請給空字串，不要編造。' },
          { role: 'user', content: prompt }
        ]
      })
    });

    if (!aiRes.ok) {
      const err = await aiRes.text();
      return json({ error: 'OpenAI API failed', detail: err }, 502);
    }
    const aiJson = await aiRes.json();
    const content = aiJson.choices?.[0]?.message?.content || '{}';
    const parsed = JSON.parse(content);
    return json({ ...parsed, source_url, confidence: parsed.confidence || 'medium' }, 200);
  } catch (err) {
    return json({ error: String(err?.message || err) }, 500);
  }
});

function buildPrompt(text: string, url: string) {
  return `請根據以下來源，為 P106「現在要去哪裡」產生欄位建議。\n\n重要原則：\n1. 這是「儲存前建議」，不是自動儲存。\n2. 不確定的欄位留空，不要幻想。\n3. 重點是未來何時該被喚回，例如地區、時間、同行者、情境、路線。\n4. 請輸出 JSON，欄位固定如下：\n{\n  "name": "",\n  "area": "",\n  "route_tag": "",\n  "place_type": "吃/喝/走走/景點/展覽/活動/伴手禮/其他",\n  "mentioned_by": "",\n  "time_tags": "",\n  "context_tags": "",\n  "budget_level": "",\n  "mood_tags": "",\n  "parking_note": "",\n  "reservation_note": "",\n  "trigger_note": "",\n  "intent_note": "",\n  "constraints_note": "",\n  "ai_summary": "",\n  "confidence": "high/medium/low"\n}\n\n來源網址：${url || '(無)'}\n\n來源內容：\n${text || '(網址內容可能讀取失敗，請根據網址本身能判斷的資訊整理；不能判斷就留空。)'}`;
}

async function tryFetchReadableText(url: string) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'P106-Personal-Experience-Retrieval/1.0' } });
    if (!res.ok) return '';
    const html = await res.text();
    return html
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 10000);
  } catch (_) {
    return '';
  }
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8' }
  });
}
