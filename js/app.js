(() => {
  const cfg = window.P106_SUPABASE_CONFIG || {};
  const hasSupabase = Boolean(cfg.url && cfg.anonKey && !cfg.url.includes('YOUR_PROJECT_ID'));
  const sb = hasSupabase && window.supabase ? window.supabase.createClient(cfg.url, cfg.anonKey) : null;
  const LS_PLACES = 'P106_LOCAL_PLACES_V1';
  const LS_COMPANIONS = 'P106_LOCAL_COMPANIONS_V1';
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  const state = { places: [], companions: [], currentView: 'now' };

  const emptyToNull = (v) => String(v || '').trim() || null;
  const splitTags = (v) => String(v || '').split(/[，,、\n]/).map(s => s.trim()).filter(Boolean);
  const formData = (form) => Object.fromEntries(new FormData(form).entries());
  const nowIso = () => new Date().toISOString();
  const uid = () => crypto.randomUUID ? crypto.randomUUID() : `local-${Date.now()}-${Math.random().toString(16).slice(2)}`;

  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 2400);
  }

  function setStatus() {
    const label = hasSupabase ? 'Supabase 已連線' : '示範模式：localStorage';
    $('#systemStatus').textContent = label;
    $('#settingsStatus').textContent = label;
  }

  async function loadData() {
    if (sb) {
      const [{ data: places, error: pErr }, { data: notes, error: nErr }, { data: sources, error: sErr }, { data: companions, error: cErr }] = await Promise.all([
        sb.from('TblP106Places').select('*').order('created_at', { ascending: false }),
        sb.from('TblP106UserPlaceNotes').select('*').order('created_at', { ascending: false }),
        sb.from('TblP106Sources').select('*').order('created_at', { ascending: false }),
        sb.from('TblP106Companions').select('*').order('created_at', { ascending: false })
      ]);
      if (pErr) toast(`讀取地點失敗：${pErr.message}`);
      if (nErr) toast(`讀取個人紀錄失敗：${nErr.message}`);
      if (sErr) toast(`讀取來源失敗：${sErr.message}`);
      if (cErr) toast(`讀取同行者失敗：${cErr.message}`);
      state.places = normalizePlaces(places || [], notes || [], sources || []);
      state.companions = companions || [];
    } else {
      state.places = JSON.parse(localStorage.getItem(LS_PLACES) || '[]');
      state.companions = JSON.parse(localStorage.getItem(LS_COMPANIONS) || '[]');
    }
    renderAll();
  }

  function normalizePlaces(rows, notes = [], sources = []) {
    return rows.map(p => {
      const note = notes.find(n => n.place_id === p.id) || null;
      const source = sources.find(s => s.place_id === p.id) || null;
      return { ...p, note, source };
    });
  }

  async function savePlace(input) {
    const place = {
      id: input.id || uid(),
      name: emptyToNull(input.name),
      area: emptyToNull(input.area),
      route_tag: emptyToNull(input.route_tag),
      place_type: emptyToNull(input.place_type) || '其他',
      address: emptyToNull(input.address),
      google_maps_url: emptyToNull(input.google_maps_url),
      official_url: emptyToNull(input.official_url),
      status_public: '待確認',
      created_at: input.created_at || nowIso(),
      updated_at: nowIso()
    };
    const note = {
      id: input.note_id || uid(),
      place_id: place.id,
      owner_name: emptyToNull(input.owner_name) || '我',
      mentioned_by: emptyToNull(input.mentioned_by),
      personal_status: emptyToNull(input.status) || emptyToNull(input.personal_status) || '未去',
      desire_level: emptyToNull(input.desire_level) || '想去',
      intent_note: emptyToNull(input.intent_note),
      trigger_note: emptyToNull(input.trigger_note),
      context_tags: splitTags(input.context_tags || input.intent || input.place_type),
      mood_tags: splitTags(input.mood_tags),
      time_tags: splitTags(input.time_tags || input.time_budget),
      constraints_note: emptyToNull(input.constraints_note || input.constraints),
      budget_level: emptyToNull(input.budget_level),
      parking_note: emptyToNull(input.parking_note),
      reservation_note: emptyToNull(input.reservation_note),
      rating: input.rating ? Number(input.rating) : null,
      revisit: Boolean(input.revisit || false),
      remind_nearby: true,
      created_at: input.note_created_at || nowIso(),
      updated_at: nowIso()
    };
    const source = input.source_url || input.source_text || input.ai_summary ? {
      id: input.source_id || uid(),
      place_id: place.id,
      source_type: input.ai_summary ? 'AI整理' : (input.source_url ? 'URL' : '文字'),
      source_url: emptyToNull(input.source_url),
      source_text: emptyToNull(input.source_text),
      ai_summary: emptyToNull(input.ai_summary),
      ai_suggested_json: input.ai_suggested_json || null,
      created_at: nowIso()
    } : null;

    if (sb) {
      const { error: pErr } = await sb.from('TblP106Places').upsert(place);
      if (pErr) throw pErr;
      const { error: nErr } = await sb.from('TblP106UserPlaceNotes').upsert(note);
      if (nErr) throw nErr;
      if (source) {
        const { error: sErr } = await sb.from('TblP106Sources').upsert(source);
        if (sErr) throw sErr;
      }
    } else {
      const record = { ...place, note, source };
      const idx = state.places.findIndex(p => p.id === place.id);
      if (idx >= 0) state.places[idx] = record; else state.places.unshift(record);
      localStorage.setItem(LS_PLACES, JSON.stringify(state.places));
    }
    await loadData();
  }

  async function saveCompanion(input) {
    const row = { id: uid(), name: input.name, relation: emptyToNull(input.relation), preference_note: emptyToNull(input.preference_note), created_at: nowIso(), updated_at: nowIso() };
    if (sb) {
      const { error } = await sb.from('TblP106Companions').insert(row);
      if (error) throw error;
    } else {
      state.companions.unshift(row);
      localStorage.setItem(LS_COMPANIONS, JSON.stringify(state.companions));
    }
    await loadData();
  }

  async function deletePlace(id) {
    if (!confirm('確定刪除此地點與相關個人紀錄？')) return;
    if (sb) {
      const { error } = await sb.from('TblP106Places').delete().eq('id', id);
      if (error) return toast(`刪除失敗：${error.message}`);
    } else {
      state.places = state.places.filter(p => p.id !== id);
      localStorage.setItem(LS_PLACES, JSON.stringify(state.places));
    }
    toast('已刪除');
    await loadData();
  }

  function scorePlace(place, q) {
    const hay = `${place.name || ''} ${place.area || ''} ${place.route_tag || ''} ${place.place_type || ''} ${place.note?.mentioned_by || ''} ${place.note?.intent_note || ''} ${place.note?.trigger_note || ''} ${(place.note?.context_tags || []).join(' ')} ${(place.note?.mood_tags || []).join(' ')} ${(place.note?.time_tags || []).join(' ')} ${place.note?.constraints_note || ''}`.toLowerCase();
    let score = 0;
    const checks = [q.area, q.time_budget, q.companions, q.intent, q.constraints].filter(Boolean);
    checks.forEach(c => splitTags(c).concat([c]).forEach(term => { if (term && hay.includes(term.toLowerCase())) score += 2; }));
    if (place.note?.personal_status === '未去') score += 1;
    if (place.note?.desire_level?.includes('很')) score += 2;
    if (place.note?.trigger_note) score += 1;
    return score;
  }

  function queryNow(q) {
    const rows = state.places.map(p => ({ ...p, _score: scorePlace(p, q) })).filter(p => p._score > 0 || !Object.values(q).some(Boolean));
    if (q.sort_by === 'desire') rows.sort((a,b) => String(b.note?.desire_level || '').localeCompare(String(a.note?.desire_level || '')));
    else if (q.sort_by === 'rating') rows.sort((a,b) => (b.note?.rating || 0) - (a.note?.rating || 0));
    else if (q.sort_by === 'recent') rows.sort((a,b) => new Date(b.created_at) - new Date(a.created_at));
    else rows.sort((a,b) => b._score - a._score);
    return rows;
  }

  function card(place) {
    const note = place.note || {};
    const tags = [place.area, place.place_type, note.personal_status, note.mentioned_by ? `誰提過：${note.mentioned_by}` : null, ...(note.context_tags || []), ...(note.time_tags || [])].filter(Boolean);
    return `<article class="place-card">
      <h3>${escapeHtml(place.name || '未命名地點')}</h3>
      <p class="muted small">${escapeHtml(note.intent_note || note.trigger_note || '尚無備註')}</p>
      <div class="meta">${tags.slice(0,8).map((t,i)=>`<span class="tag ${i===2?'hot':''}">${escapeHtml(t)}</span>`).join('')}</div>
      <p class="small"><strong>何時想起：</strong>${escapeHtml(note.trigger_note || '尚未設定')}</p>
      <div class="card-actions">
        <button class="secondary" data-detail="${place.id}">詳情</button>
        ${place.google_maps_url ? `<a class="secondary" href="${escapeAttr(place.google_maps_url)}" target="_blank" rel="noreferrer">Google Maps</a>` : ''}
        <button class="danger" data-delete="${place.id}">刪除</button>
      </div>
    </article>`;
  }

  function renderCards(container, rows, emptyMsg='目前沒有資料') {
    container.innerHTML = rows.length ? rows.map(card).join('') : `<div class="panel muted">${emptyMsg}</div>`;
  }

  function renderLibrary() {
    const q = $('#librarySearch')?.value?.toLowerCase() || '';
    const status = $('#libraryStatus')?.value || '';
    let rows = [...state.places];
    if (q) rows = rows.filter(p => JSON.stringify(p).toLowerCase().includes(q));
    if (status) rows = rows.filter(p => p.note?.personal_status === status);
    renderCards($('#libraryList'), rows);
  }

  function renderPending() {
    const rows = state.places.filter(p => !p.area || !p.note?.trigger_note || !p.note?.intent_note);
    renderCards($('#pendingList'), rows, '目前沒有待整理資料。');
  }

  function renderCompanions() {
    $('#companionList').innerHTML = state.companions.length ? state.companions.map(c => `<article class="place-card"><h3>${escapeHtml(c.name)}</h3><p class="muted">${escapeHtml(c.relation || '')}</p><p>${escapeHtml(c.preference_note || '尚未記錄偏好')}</p></article>`).join('') : '<div class="panel muted">尚未建立同行者。</div>';
  }

  function renderAll() { renderLibrary(); renderPending(); renderCompanions(); }

  function showDetail(id) {
    const p = state.places.find(x => x.id === id);
    if (!p) return;
    const n = p.note || {}; const s = p.source || {};
    $('#detailContent').innerHTML = `<h2>${escapeHtml(p.name || '未命名地點')}</h2>
      <p class="muted">${escapeHtml(p.area || '')}｜${escapeHtml(p.place_type || '')}</p>
      <hr>
      <p><strong>誰提過：</strong>${escapeHtml(n.mentioned_by || '未記錄')}</p>
      <p><strong>狀態：</strong>${escapeHtml(n.personal_status || '未記錄')}　<strong>意願：</strong>${escapeHtml(n.desire_level || '未記錄')}</p>
      <p><strong>為什麼想去：</strong>${escapeHtml(n.intent_note || '未記錄')}</p>
      <p><strong>什麼時候要想起：</strong>${escapeHtml(n.trigger_note || '未記錄')}</p>
      <p><strong>情境標籤：</strong>${escapeHtml((n.context_tags || []).join('、') || '未記錄')}</p>
      <p><strong>時間標籤：</strong>${escapeHtml((n.time_tags || []).join('、') || '未記錄')}</p>
      <p><strong>限制：</strong>${escapeHtml(n.constraints_note || '未記錄')}</p>
      <p><strong>AI 摘要：</strong>${escapeHtml(s.ai_summary || '無')}</p>
      ${s.source_url ? `<p><strong>來源：</strong><a href="${escapeAttr(s.source_url)}" target="_blank" rel="noreferrer">開啟來源</a></p>` : ''}`;
    $('#detailDialog').showModal();
  }

  async function analyzeInput(input) {
    if (sb && cfg.edgeFunctionBaseUrl) {
      const url = `${cfg.edgeFunctionBaseUrl.replace(/\/$/, '')}/P106AnalyzeInput`;
      const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${cfg.anonKey}` }, body: JSON.stringify(input) });
      if (!res.ok) throw new Error(await res.text());
      return await res.json();
    }
    const text = `${input.source_text || ''} ${input.source_url || ''}`;
    const nameGuess = text.match(/「([^」]{2,30})」/)?.[1] || text.split(/[\n。]/)[0]?.slice(0,24) || '待命名地點';
    return {
      name: nameGuess,
      area: guess(text, ['花蓮','台東','台11線','台北','中山','京都','台南']) || '',
      place_type: guess(text, ['咖啡','甜點','餐廳','海灘','展覽','景點']) || '其他',
      mentioned_by: '',
      time_tags: guess(text, ['早餐','午餐','晚餐','下午茶','三小時','半天','週末']) || '',
      context_tags: guess(text, ['約會','朋友','家人','外賓','看海','拍照','聊天']) || '',
      budget_level: '', mood_tags: '', parking_note: '', reservation_note: '',
      trigger_note: '到附近、有空檔時可喚回',
      intent_note: text.slice(0,160),
      ai_summary: text ? text.slice(0,220) : '示範模式下產生的欄位建議。',
      confidence: 'demo'
    };
  }

  function guess(text, words) { return words.filter(w => text.includes(w)).slice(0,3).join('、'); }

  function setView(view) {
    state.currentView = view;
    $$('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.view === view));
    $$('.view').forEach(v => v.classList.toggle('active', v.id === `view-${view}`));
    const titles = {
      now: ['現在要去哪裡', '輸入當下情境，從自己與小群體的生活記憶中找出合適候選。'],
      quick: ['快速記一下', '平常看到、聽到、想到的地點，先用最少欄位保存。'],
      ai: ['AI 幫我整理', '把文字或網址轉成欄位建議，人工確認後再儲存。'],
      library: ['我的收藏', '管理所有曾經想去、已去、想再去或待確認的地點。'],
      pending: ['待整理', '補齊快速輸入資料，讓未來更容易被喚回。'],
      companions: ['同行者', '記錄親友、學生或外賓的偏好與限制。'],
      settings: ['設定', '檢查 Supabase 設定與匯出資料。']
    };
    $('#viewTitle').textContent = titles[view][0]; $('#viewSubtitle').textContent = titles[view][1];
  }

  function escapeHtml(str) { return String(str ?? '').replace(/[&<>"]/g, s => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[s])); }
  function escapeAttr(str) { return escapeHtml(str).replace(/'/g, '&#39;'); }

  function bindEvents() {
    $$('.nav-btn').forEach(b => b.addEventListener('click', () => setView(b.dataset.view)));
    $('#nowForm').addEventListener('submit', e => {
      e.preventDefault();
      const form = e.currentTarget;
      renderCards($('#nowResults'), queryNow(formData(form)), '沒有符合條件的喚回結果。可以放寬地區、時間或同行者條件。');
    });
    $('#clearNow').addEventListener('click', () => { $('#nowForm').reset(); $('#nowResults').innerHTML = ''; });
    $('#quickForm').addEventListener('submit', async e => {
      e.preventDefault();
      const form = e.currentTarget;
      try {
        await savePlace(formData(form));
        form.reset();
        toast('已快速儲存');
        setView('library');
      } catch(err) { toast(`儲存失敗：${err.message}`); }
    });
    $('#aiForm').addEventListener('submit', async e => {
      e.preventDefault();
      const form = e.currentTarget;
      try {
        toast('正在產生欄位建議');
        const input = formData(form);
        const data = await analyzeInput(input);
        const f = $('#aiConfirmForm');
        f.classList.remove('hidden');
        Object.entries(data).forEach(([k,v]) => {
          const el = f.elements[k];
          if (el) el.value = Array.isArray(v) ? v.join('、') : (v || '');
        });
        f.dataset.sourceUrl = input.source_url || '';
        f.dataset.sourceText = input.source_text || '';
        f.dataset.aiJson = JSON.stringify(data);
        toast('已產生建議，請確認後儲存');
      } catch(err) { toast(`AI 分析失敗：${err.message}`); }
    });
    $('#aiConfirmForm').addEventListener('submit', async e => {
      e.preventDefault();
      const form = e.currentTarget;
      try {
        const data = formData(form);
        data.source_url = form.dataset.sourceUrl;
        data.source_text = form.dataset.sourceText;
        data.ai_suggested_json = JSON.parse(form.dataset.aiJson || '{}');
        await savePlace(data);
        form.reset();
        form.classList.add('hidden');
        toast('已儲存 AI 建議資料');
        setView('library');
      } catch(err) { toast(`儲存失敗：${err.message}`); }
    });
    $('#discardAi').addEventListener('click', () => $('#aiConfirmForm').classList.add('hidden'));
    $('#librarySearch').addEventListener('input', renderLibrary); $('#libraryStatus').addEventListener('change', renderLibrary); $('#refreshLibrary').addEventListener('click', loadData);
    document.body.addEventListener('click', e => { const detail = e.target.closest('[data-detail]'); const del = e.target.closest('[data-delete]'); if (detail) showDetail(detail.dataset.detail); if (del) deletePlace(del.dataset.delete); });
    $('#companionForm').addEventListener('submit', async e => {
      e.preventDefault();
      const form = e.currentTarget;
      try {
        await saveCompanion(formData(form));
        form.reset();
        toast('已新增同行者');
      } catch(err) { toast(`新增失敗：${err.message}`); }
    });
    $('#exportJson').addEventListener('click', () => { const blob = new Blob([JSON.stringify({ places: state.places, companions: state.companions }, null, 2)], {type:'application/json'}); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `P106_export_${new Date().toISOString().slice(0,10)}.json`; a.click(); URL.revokeObjectURL(a.href); });
  }

  setStatus(); bindEvents(); loadData();
})();
