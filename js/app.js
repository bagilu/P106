'use strict';

const cfg = window.P106_CONFIG || {};
const toastEl = document.getElementById('toast');
const authPanel = document.getElementById('authPanel');
const appPanel = document.getElementById('appPanel');
const currentUserLabel = document.getElementById('currentUserLabel');
const logoutBtn = document.getElementById('logoutBtn');
const supabaseReady = cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY && !cfg.SUPABASE_URL.includes('YOUR_');
const db = supabaseReady ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;
let currentUser = null;
let placesCache = [];
let companionsCache = [];

function showToast(msg, isError=false){
  toastEl.textContent = msg; toastEl.classList.remove('hidden');
  toastEl.style.background = isError ? '#8c2f26' : '#25312a';
  clearTimeout(showToast._t); showToast._t = setTimeout(()=>toastEl.classList.add('hidden'), 3600);
}
function setMessage(id,msg){ const el=document.getElementById(id); if(el) el.textContent=msg||''; }
function formData(form){ return Object.fromEntries(new FormData(form).entries()); }
function csvTags(text){ return (text||'').split(/[，,、\s]+/).map(s=>s.trim()).filter(Boolean); }
function joinTags(v){ return Array.isArray(v) ? v.join('、') : (v||''); }
function esc(s){ return String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c])); }
function ensureDb(){ if(!db){ showToast('請先將 config.sample.js 複製為 config.js，並填入 Supabase URL 與 anon key。', true); return false; } return true; }

async function init(){
  if(!ensureDb()) return;
  bindTabs(); bindForms();
  const { data } = await db.auth.getSession();
  currentUser = data.session?.user || null;
  renderAuthState();
  db.auth.onAuthStateChange((_event, session)=>{ currentUser = session?.user || null; renderAuthState(); if(currentUser) loadAll(); });
  if(currentUser) await loadAll();
}

function renderAuthState(){
  if(currentUser){
    authPanel.classList.add('hidden'); appPanel.classList.remove('hidden'); logoutBtn.classList.remove('hidden');
    currentUserLabel.textContent = currentUser.email || currentUser.id;
  }else{
    authPanel.classList.remove('hidden'); appPanel.classList.add('hidden'); logoutBtn.classList.add('hidden');
    currentUserLabel.textContent = '尚未登入';
  }
}

function bindTabs(){
  document.querySelectorAll('.tab').forEach(btn=>btn.addEventListener('click',()=>{
    document.querySelectorAll('.tab').forEach(b=>b.classList.remove('active'));
    document.querySelectorAll('.tab-page').forEach(p=>p.classList.remove('active'));
    btn.classList.add('active'); document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
  }));
}

function bindForms(){
  document.getElementById('loginForm').addEventListener('submit', async e=>{
    e.preventDefault(); const form=e.currentTarget; const d=formData(form); setMessage('authMessage','登入中...');
    const { error } = await db.auth.signInWithPassword({email:d.email,password:d.password});
    if(error){ setMessage('authMessage', error.message); showToast('登入失敗', true); } else { form.reset(); setMessage('authMessage','登入成功'); }
  });
  document.getElementById('signupForm').addEventListener('submit', async e=>{
    e.preventDefault(); const form=e.currentTarget; const d=formData(form); setMessage('authMessage','建立帳號中...');
    const { error } = await db.auth.signUp({email:d.email,password:d.password});
    if(error){ setMessage('authMessage', error.message); showToast('註冊失敗', true); } else { form.reset(); setMessage('authMessage','帳號已建立。若系統要求驗證，請先至信箱完成驗證。'); showToast('註冊完成'); }
  });
  logoutBtn.addEventListener('click', async()=>{ await db.auth.signOut(); placesCache=[]; companionsCache=[]; });
  document.getElementById('quickForm').addEventListener('submit', saveQuickPlace);
  document.getElementById('companionForm').addEventListener('submit', saveCompanion);
  document.getElementById('searchForm').addEventListener('submit', doContextSearch);
  document.getElementById('clearSearchBtn').addEventListener('click',()=>{document.getElementById('searchForm').reset(); renderPlaces(placesCache,'searchResults');});
  document.getElementById('reloadBtn').addEventListener('click', loadAll);
  document.getElementById('placeKeyword').addEventListener('input', renderFilteredPlaces);
  document.getElementById('statusFilter').addEventListener('change', renderFilteredPlaces);
  document.getElementById('editForm').addEventListener('submit', saveEdit);
}

async function loadAll(){
  if(!currentUser) return;
  await Promise.all([loadCompanions(), loadPlaces()]);
  renderFilteredPlaces(); renderPending(); renderPlaces(placesCache,'searchResults');
}

async function loadPlaces(){
  const { data, error } = await db.from('TblP106Places').select('*').order('UpdatedAt',{ascending:false});
  if(error){ showToast('讀取收藏失敗：'+error.message,true); return; }
  placesCache = data || [];
}
async function loadCompanions(){
  const { data, error } = await db.from('TblP106Companions').select('*').order('CreatedAt',{ascending:false});
  if(error){ showToast('讀取同行者失敗：'+error.message,true); return; }
  companionsCache = data || [];
  renderCompanionOptions(); renderCompanions();
}
function renderCompanionOptions(){
  const opts = ['<option value="">自己／未指定</option>'].concat(companionsCache.map(c=>`<option value="${esc(c.CompanionId)}">${esc(c.CompanionName)}</option>`)).join('');
  document.getElementById('quickCompanion').innerHTML=opts; document.getElementById('searchCompanion').innerHTML=opts;
}
function companionName(id){ return companionsCache.find(c=>c.CompanionId===id)?.CompanionName || ''; }

async function saveQuickPlace(e){
  e.preventDefault(); const form=e.currentTarget; const d=formData(form);
  const payload = {
    PlaceName:d.PlaceName, AreaText:d.AreaText||null, RouteTag:d.RouteTag||null, PlaceType:d.PlaceType||null,
    VisitStatus:d.VisitStatus||'未去', DesireLevel:d.DesireLevel||'待確認', MentionedByCompanionId:d.MentionedByCompanionId||null,
    TimeTags:csvTags(d.TimeTags), TriggerTags:csvTags(d.TriggerTags), PersonalNote:d.PersonalNote||null,
    GoogleMapsUrl:d.GoogleMapsUrl||null, SourceUrl:d.SourceUrl||null, BudgetLevel:d.BudgetLevel||null,
    MoodTags:csvTags(d.MoodTags), ParkingNote:d.ParkingNote||null, ReservationNote:d.ReservationNote||null
  };
  const { error } = await db.from('TblP106Places').insert(payload);
  if(error){ showToast('儲存失敗：'+error.message,true); return; }
  form.reset(); showToast('已儲存到我的收藏'); await loadAll();
}

async function saveCompanion(e){
  e.preventDefault(); const form=e.currentTarget; const d=formData(form);
  const payload={CompanionName:d.CompanionName,RelationLabel:d.RelationLabel||null,PreferenceTags:csvTags(d.PreferenceTags),AvoidanceTags:csvTags(d.AvoidanceTags),Notes:d.Notes||null};
  const { error } = await db.from('TblP106Companions').insert(payload);
  if(error){ showToast('新增失敗：'+error.message,true); return; }
  form.reset(); showToast('已新增同行者'); await loadCompanions();
}

function scorePlace(p, criteria){
  let score=0; const hay=[p.PlaceName,p.AreaText,p.RouteTag,p.PlaceType,p.PersonalNote,joinTags(p.TriggerTags),joinTags(p.TimeTags),joinTags(p.MoodTags),p.BudgetLevel,p.ParkingNote,p.ReservationNote].join(' ').toLowerCase();
  [criteria.area,criteria.timeBudget,criteria.activity,criteria.limits].filter(Boolean).forEach(q=>{ if(hay.includes(q.toLowerCase())) score+=2; });
  if(criteria.companion && p.MentionedByCompanionId===criteria.companion) score+=4;
  if(p.DesireLevel==='很想去') score+=2; if(p.VisitStatus==='未去'||p.VisitStatus==='想再去') score+=1;
  return score;
}
function doContextSearch(e){
  e.preventDefault(); const d=formData(e.currentTarget);
  const ranked = placesCache.map(p=>({...p,_score:scorePlace(p,d)})).filter(p=>p._score>0 || (!d.area&&!d.timeBudget&&!d.activity&&!d.limits&&!d.companion)).sort((a,b)=>b._score-a._score || new Date(b.UpdatedAt)-new Date(a.UpdatedAt));
  renderPlaces(ranked,'searchResults',true);
}
function renderFilteredPlaces(){
  const kw=(document.getElementById('placeKeyword').value||'').toLowerCase(); const st=document.getElementById('statusFilter').value;
  const rows=placesCache.filter(p=>{ const hay=JSON.stringify(p).toLowerCase(); return (!kw||hay.includes(kw)) && (!st||p.VisitStatus===st); });
  renderPlaces(rows,'placesList');
}
function renderPending(){
  const rows=placesCache.filter(p=>!p.AreaText || !p.TriggerTags?.length || !p.PersonalNote);
  renderPlaces(rows,'pendingList');
}
function renderPlaces(rows, targetId, showScore=false){
  const target=document.getElementById(targetId); target.innerHTML='';
  if(!rows.length){ target.innerHTML='<div class="card"><h3>目前沒有符合資料</h3><p class="meta">可以先到「快速記一下」新增收藏。</p></div>'; return; }
  const tpl=document.getElementById('placeCardTemplate');
  rows.forEach(p=>{
    const node=tpl.content.cloneNode(true); node.querySelector('h3').textContent=p.PlaceName; node.querySelector('.badge').textContent=showScore?`適合度 ${p._score}`:(p.VisitStatus||'未去');
    node.querySelector('.meta').textContent=[p.AreaText,p.RouteTag,p.PlaceType,companionName(p.MentionedByCompanionId)&&`誰提過：${companionName(p.MentionedByCompanionId)}`].filter(Boolean).join('｜');
    node.querySelector('.note').textContent=p.PersonalNote || '尚未填寫個人備註。';
    const chipBox=node.querySelector('.chips'); [...(p.TriggerTags||[]),...(p.TimeTags||[]),...(p.MoodTags||[]),p.DesireLevel,p.BudgetLevel].filter(Boolean).forEach(t=>{ const c=document.createElement('span'); c.className='chip'; c.textContent=t; chipBox.appendChild(c); });
    const maps=node.querySelector('.maps-link'); if(p.GoogleMapsUrl){ maps.href=p.GoogleMapsUrl; } else { maps.classList.add('hidden'); }
    node.querySelector('.candidate-btn').addEventListener('click',()=>addCandidate(p.PlaceId));
    node.querySelector('.edit-btn').addEventListener('click',()=>openEdit(p));
    node.querySelector('.delete-btn').addEventListener('click',()=>deletePlace(p.PlaceId));
    target.appendChild(node);
  });
}
async function addCandidate(placeId){
  const { error } = await db.from('TblP106TodayCandidates').insert({PlaceId:placeId,CandidateDate:new Date().toISOString().slice(0,10),CandidateStatus:'候選'});
  showToast(error?'加入候選失敗：'+error.message:'已加入今日候選',!!error);
}
function openEdit(p){
  const form=document.getElementById('editForm'); form.PlaceId.value=p.PlaceId; form.PlaceName.value=p.PlaceName||''; form.AreaText.value=p.AreaText||''; form.RouteTag.value=p.RouteTag||''; form.PlaceType.value=p.PlaceType||''; form.VisitStatus.value=p.VisitStatus||''; form.DesireLevel.value=p.DesireLevel||''; form.TriggerTags.value=joinTags(p.TriggerTags); form.PersonalNote.value=p.PersonalNote||''; form.GoogleMapsUrl.value=p.GoogleMapsUrl||'';
  document.getElementById('editDialog').showModal();
}
async function saveEdit(e){
  const form=e.currentTarget; if(form.returnValue==='cancel') return;
  e.preventDefault(); const d=formData(form);
  const payload={PlaceName:d.PlaceName,AreaText:d.AreaText||null,RouteTag:d.RouteTag||null,PlaceType:d.PlaceType||null,VisitStatus:d.VisitStatus||null,DesireLevel:d.DesireLevel||null,TriggerTags:csvTags(d.TriggerTags),PersonalNote:d.PersonalNote||null,GoogleMapsUrl:d.GoogleMapsUrl||null};
  const { error } = await db.from('TblP106Places').update(payload).eq('PlaceId',d.PlaceId);
  if(error){ showToast('更新失敗：'+error.message,true); return; }
  document.getElementById('editDialog').close(); showToast('已更新'); await loadAll();
}
async function deletePlace(placeId){
  if(!confirm('確定刪除此筆收藏？只會刪除目前登入者自己的資料。')) return;
  const { error } = await db.from('TblP106Places').delete().eq('PlaceId',placeId);
  if(error){ showToast('刪除失敗：'+error.message,true); return; }
  showToast('已刪除'); await loadAll();
}
function renderCompanions(){
  const box=document.getElementById('companionsList'); box.innerHTML='';
  if(!companionsCache.length){ box.innerHTML='<div class="card"><h3>尚無同行者</h3><p class="meta">可以新增家人、朋友、學生、外賓等。</p></div>'; return; }
  companionsCache.forEach(c=>{ const el=document.createElement('article'); el.className='card'; el.innerHTML=`<div class="card-head"><h3>${esc(c.CompanionName)}</h3><span class="badge">${esc(c.RelationLabel||'同行者')}</span></div><p class="meta">喜好：${esc(joinTags(c.PreferenceTags)||'未填')}</p><p class="meta">避免：${esc(joinTags(c.AvoidanceTags)||'未填')}</p><p>${esc(c.Notes||'')}</p>`; box.appendChild(el); });
}

init().catch(err=>showToast(err.message||String(err),true));
