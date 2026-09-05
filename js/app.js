"use strict";

const cfg = window.P106_CONFIG || {};
const supabaseReady = cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY && !String(cfg.SUPABASE_URL).includes("YOUR_");
const db = supabaseReady ? window.supabase.createClient(
  cfg.SUPABASE_URL,
  cfg.SUPABASE_ANON_KEY,
  { auth: { storageKey: "p106-auth-token", persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }
) : null;

const DEFINITIONS = {
  categories: [["FOOD","食"],["STAY","住"],["SCENIC","景"]],
  budgets: [
    ["B000_200","0–200"],["B200_400","200–400"],["B400_800","400–800"],["B800_1600","800–1600"],
    ["B1600_3200","1600–3200"],["B3200_6400","3200–6400"],["B6400_12800","6400–12800"],["B12800_PLUS","12800以上"]
  ],
  atmospheres: [["LUXURY","奢華"],["ELEGANT","高雅"],["ARTSY","文青"],["SIMPLE","簡陋"],["LOUD","喧嘩"],["QUIET","安靜"]],
  parkingLevels: [["CONVENIENT","方便"],["NORMAL","普通"],["INCONVENIENT","不方便"]],
  stationDistances: [["NEAR","近"],["NORMAL","普通"],["FAR","遠"]],
  partySizes: [["ONE","1人"],["TWO","2人"],["THREE_FOUR","3–4人"],["FIVE_EIGHT","5–8人"],["NINE_PLUS","9人以上"]],
  timeSlots: [["05_08","清晨 05–08"],["08_11","上午 08–11"],["11_14","中午 11–14"],["14_17","下午 14–17"],["17_21","晚間 17–21"],["21_05","深夜 21–05"]]
};

const COUNTRIES = [["TW","台灣"],["CN","大陸"],["JP","日本"],["US","美國"],["OTHER","其他"]];
const REGIONS = {
  TW:["基隆市","台北市","新北市","桃園市","新竹市","新竹縣","苗栗縣","台中市","彰化縣","南投縣","雲林縣","嘉義市","嘉義縣","台南市","高雄市","屏東縣","宜蘭縣","花蓮縣","台東縣","澎湖縣","金門縣","連江縣"],
  CN:["北京市","天津市","上海市","重慶市","河北省","山西省","遼寧省","吉林省","黑龍江省","江蘇省","浙江省","安徽省","福建省","江西省","山東省","河南省","湖北省","湖南省","廣東省","海南省","四川省","貴州省","雲南省","陝西省","甘肅省","青海省","內蒙古自治區","廣西壯族自治區","西藏自治區","寧夏回族自治區","新疆維吾爾自治區"],
  JP:["北海道","青森縣","岩手縣","宮城縣","秋田縣","山形縣","福島縣","茨城縣","栃木縣","群馬縣","埼玉縣","千葉縣","東京都","神奈川縣","新潟縣","富山縣","石川縣","福井縣","山梨縣","長野縣","岐阜縣","靜岡縣","愛知縣","三重縣","滋賀縣","京都府","大阪府","兵庫縣","奈良縣","和歌山縣","鳥取縣","島根縣","岡山縣","廣島縣","山口縣","德島縣","香川縣","愛媛縣","高知縣","福岡縣","佐賀縣","長崎縣","熊本縣","大分縣","宮崎縣","鹿兒島縣","沖繩縣"],
  US:["Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut","Delaware","Florida","Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming","District of Columbia"]
};

let currentUser = null;
let myPlaces = [];
let publicPlaces = [];
let searchScope = "mine";
let editingPlaceId = null;

const $ = id => document.getElementById(id);
const toastEl = $("toast");

function showToast(message, isError=false){
  toastEl.textContent = message;
  toastEl.style.background = isError ? "#8c2f26" : "#25312a";
  toastEl.classList.remove("hidden");
  clearTimeout(showToast._timer);
  showToast._timer = setTimeout(()=>toastEl.classList.add("hidden"), 3600);
}
function setMessage(message){ $("authMessage").textContent = message || ""; }
function ensureDb(){
  if(!db){ showToast("請保留既有 config.js，或由 config.sample.js 建立 config.js 並填入 Supabase 設定。", true); return false; }
  return true;
}
function escapeHtml(value){
  return String(value ?? "").replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
}
function labelsFor(values, defKey){
  const map = Object.fromEntries(DEFINITIONS[defKey]);
  return (values || []).map(v=>map[v] || v);
}
function countryLabel(code){ return Object.fromEntries(COUNTRIES)[code] || code || ""; }
function selectedValues(containerId){
  return [...document.querySelectorAll(`#${containerId} input[type="checkbox"]:checked`)].map(x=>x.value);
}
function setSelectedValues(containerId, values=[]){
  const set = new Set(values || []);
  document.querySelectorAll(`#${containerId} input[type="checkbox"]`).forEach(x=>x.checked=set.has(x.value));
}
function renderChoices(containerId, defKey, namePrefix){
  const container = $(containerId);
  container.innerHTML = DEFINITIONS[defKey].map(([value,label]) =>
    `<label class="choice"><input type="checkbox" value="${escapeHtml(value)}" data-group="${escapeHtml(namePrefix)}"><span>${escapeHtml(label)}</span></label>`
  ).join("");
}
function renderCountries(selectId){
  $(selectId).innerHTML = COUNTRIES.map(([v,l])=>`<option value="${v}" ${v==="TW"?"selected":""}>${l}</option>`).join("");
}
function updateRegionUI(prefix){
  const country = $(`${prefix}Country`).value;
  const selectWrap = $(`${prefix}RegionSelectWrap`);
  const textWrap = $(`${prefix}RegionTextWrap`);
  const select = $(`${prefix}Region`);
  if(country === "OTHER"){
    selectWrap.classList.add("hidden"); textWrap.classList.remove("hidden");
    return;
  }
  textWrap.classList.add("hidden"); selectWrap.classList.remove("hidden");
  const list = REGIONS[country] || [];
  select.innerHTML = `<option value="">不限／未指定</option>` + list.map(x=>`<option value="${escapeHtml(x)}">${escapeHtml(x)}</option>`).join("");
}
function currentRegionValue(prefix){
  return $(`${prefix}Country`).value === "OTHER" ? $(`${prefix}RegionText`).value.trim() : $(`${prefix}Region`).value;
}
function setupStaticUI(){
  renderChoices("placeCategories","categories","placeCategories");
  renderChoices("placeBudgets","budgets","placeBudgets");
  renderChoices("placeAtmospheres","atmospheres","placeAtmospheres");
  renderChoices("placeParkingLevels","parkingLevels","placeParkingLevels");
  renderChoices("placeStationDistances","stationDistances","placeStationDistances");
  renderChoices("placePartySizes","partySizes","placePartySizes");
  renderChoices("placeTimeSlots","timeSlots","placeTimeSlots");
  renderChoices("searchCategories","categories","searchCategories");
  renderChoices("searchBudgets","budgets","searchBudgets");
  renderChoices("searchAtmospheres","atmospheres","searchAtmospheres");
  renderChoices("searchParkingLevels","parkingLevels","searchParkingLevels");
  renderChoices("searchStationDistances","stationDistances","searchStationDistances");
  renderChoices("searchPartySizes","partySizes","searchPartySizes");
  renderChoices("searchTimeSlots","timeSlots","searchTimeSlots");
  renderCountries("placeCountry"); renderCountries("searchCountry");
  updateRegionUI("place"); updateRegionUI("search");
}

async function init(){
  setupStaticUI();
  bindUI();
  if(!ensureDb()) return;
  const { data } = await db.auth.getSession();
  currentUser = data.session?.user || null;
  renderAuthState();
  db.auth.onAuthStateChange((_event, session)=>{
    currentUser = session?.user || null;
    renderAuthState();
    if(currentUser) loadAll();
  });
  if(currentUser) await loadAll();
}
function renderAuthState(){
  if(currentUser){
    $("authPanel").classList.add("hidden"); $("appPanel").classList.remove("hidden"); $("logoutBtn").classList.remove("hidden");
    $("currentUserLabel").textContent = currentUser.email || "已登入";
  }else{
    $("authPanel").classList.remove("hidden"); $("appPanel").classList.add("hidden"); $("logoutBtn").classList.add("hidden");
    $("currentUserLabel").textContent = "尚未登入";
    myPlaces=[]; publicPlaces=[];
  }
}
function activateTab(name){
  document.querySelectorAll(".tab").forEach(b=>b.classList.toggle("active", b.dataset.tab===name));
  document.querySelectorAll(".tab-page").forEach(p=>p.classList.toggle("active", p.id===`tab-${name}`));
}
function bindUI(){
  document.querySelectorAll(".tab").forEach(btn=>btn.addEventListener("click",()=>activateTab(btn.dataset.tab)));
  $("placeCountry").addEventListener("change",()=>updateRegionUI("place"));
  $("searchCountry").addEventListener("change",()=>updateRegionUI("search"));

  $("loginForm").addEventListener("submit", async e=>{
    e.preventDefault(); const form=e.currentTarget; const data=Object.fromEntries(new FormData(form));
    setMessage("登入中…");
    const { error } = await db.auth.signInWithPassword({email:data.email,password:data.password});
    if(error){ setMessage(error.message); showToast("登入失敗",true); }
    else { form.reset(); setMessage("登入成功"); }
  });

  $("signupForm").addEventListener("submit", async e=>{
    e.preventDefault(); const form=e.currentTarget; const data=Object.fromEntries(new FormData(form));
    setMessage("建立帳號中…");
    const redirect = window.location.origin + window.location.pathname;
    const { error } = await db.auth.signUp({email:data.email,password:data.password,options:{emailRedirectTo:redirect}});
    if(error){ setMessage(error.message); showToast("註冊失敗",true); }
    else { form.reset(); setMessage("帳號已建立。請到信箱完成確認後再登入。"); showToast("註冊完成"); }
  });

  $("logoutBtn").addEventListener("click",()=>db.auth.signOut());
  $("placeForm").addEventListener("submit", savePlace);
  $("resetPlaceBtn").addEventListener("click", resetPlaceForm);
  $("cancelEditBtn").addEventListener("click", resetPlaceForm);

  $("scopeMineBtn").addEventListener("click",()=>setSearchScope("mine"));
  $("scopePublicBtn").addEventListener("click",()=>setSearchScope("public"));
  $("searchForm").addEventListener("submit", doSearch);
  $("clearSearchBtn").addEventListener("click", clearSearch);
  $("useCurrentTimeBtn").addEventListener("click", selectCurrentTimeSlot);

  $("mineKeyword").addEventListener("input", renderMineList);
  $("visibilityFilter").addEventListener("change", renderMineList);
  $("reloadBtn").addEventListener("click", loadAll);
}
function setSearchScope(scope){
  searchScope=scope;
  $("scopeMineBtn").classList.toggle("active",scope==="mine");
  $("scopePublicBtn").classList.toggle("active",scope==="public");
  $("resultEyebrow").textContent=scope==="mine"?"My Memory":"Shared Memory";
  $("resultTitle").textContent=scope==="mine"?"我的地點":"公開地點";
  doSearch();
}
async function loadAll(){
  await loadMyPlaces();
  renderMineList();
  doSearch();
}
async function loadMyPlaces(){
  const { data, error } = await db.from("TblP106Places").select("*").order("UpdatedAt",{ascending:false});
  if(error){ showToast("讀取我的地點失敗："+error.message,true); return; }
  myPlaces=data||[];
}
async function loadPublicPlaces(){
  const { data, error } = await db.rpc("P106SearchPublicPlaces");
  if(error){ showToast("讀取公開地點失敗："+error.message,true); publicPlaces=[]; return; }
  publicPlaces=data||[];
}

function placePayload(form){
  const data=Object.fromEntries(new FormData(form));
  return {
    PlaceName:String(data.PlaceName||"").trim(),
    Categories:selectedValues("placeCategories"),
    BudgetRanges:selectedValues("placeBudgets"),
    CountryCode:$("placeCountry").value,
    RegionText:currentRegionValue("place") || null,
    Atmospheres:selectedValues("placeAtmospheres"),
    ParkingLevels:selectedValues("placeParkingLevels"),
    StationDistanceLevels:selectedValues("placeStationDistances"),
    PartySizes:selectedValues("placePartySizes"),
    TimeSlotsV2:selectedValues("placeTimeSlots"),
    PersonalNote:String(data.PersonalNote||"").trim() || null,
    GoogleMapsUrl:String(data.GoogleMapsUrl||"").trim() || null,
    IsPublic:data.IsPublic==="true"
  };
}
async function savePlace(e){
  e.preventDefault();
  const form=e.currentTarget;
  const payload=placePayload(form);
  if(!payload.PlaceName){ showToast("請填寫名稱。",true); return; }
  if(!payload.Categories.length){ showToast("請至少選擇「食／住／景」其中一項。",true); return; }

  let error;
  if(editingPlaceId){
    ({error}=await db.from("TblP106Places").update(payload).eq("PlaceId",editingPlaceId));
  }else{
    ({error}=await db.from("TblP106Places").insert(payload));
  }
  if(error){ showToast((editingPlaceId?"更新":"儲存")+"失敗："+error.message,true); return; }
  showToast(editingPlaceId?"已更新地點":"已儲存地點");
  resetPlaceForm();
  await loadAll();
  activateTab("mine");
}
function resetPlaceForm(){
  const form=$("placeForm"); form.reset();
  editingPlaceId=null; $("editingPlaceId").value="";
  $("placeCountry").value="TW"; updateRegionUI("place");
  setSelectedValues("placeCategories",[]); setSelectedValues("placeBudgets",[]); setSelectedValues("placeAtmospheres",[]);
  setSelectedValues("placeParkingLevels",[]); setSelectedValues("placeStationDistances",[]);
  setSelectedValues("placePartySizes",[]); setSelectedValues("placeTimeSlots",[]);
  $("addPageTitle").textContent="新增地點"; $("savePlaceBtn").textContent="儲存地點"; $("cancelEditBtn").classList.add("hidden");
}
function editPlace(placeId){
  const p=myPlaces.find(x=>x.PlaceId===placeId); if(!p) return;
  editingPlaceId=placeId; $("editingPlaceId").value=placeId;
  const form=$("placeForm"); form.PlaceName.value=p.PlaceName||"";
  $("placeCountry").value=p.CountryCode||"TW"; updateRegionUI("place");
  if($("placeCountry").value==="OTHER") $("placeRegionText").value=p.RegionText||""; else $("placeRegion").value=p.RegionText||"";
  form.PersonalNote.value=p.PersonalNote||""; form.GoogleMapsUrl.value=p.GoogleMapsUrl||""; form.IsPublic.checked=!!p.IsPublic;
  setSelectedValues("placeCategories",p.Categories); setSelectedValues("placeBudgets",p.BudgetRanges); setSelectedValues("placeAtmospheres",p.Atmospheres);
  setSelectedValues("placeParkingLevels",p.ParkingLevels); setSelectedValues("placeStationDistances",p.StationDistanceLevels);
  setSelectedValues("placePartySizes",p.PartySizes); setSelectedValues("placeTimeSlots",p.TimeSlotsV2);
  $("addPageTitle").textContent="編輯地點"; $("savePlaceBtn").textContent="儲存修改"; $("cancelEditBtn").classList.remove("hidden");
  activateTab("add"); window.scrollTo({top:0,behavior:"smooth"});
}
async function deletePlace(placeId){
  if(!confirm("確定刪除此筆地點？")) return;
  const { error }=await db.from("TblP106Places").delete().eq("PlaceId",placeId);
  if(error){ showToast("刪除失敗："+error.message,true); return; }
  showToast("已刪除"); await loadAll();
}

function searchCriteria(){
  const formData=Object.fromEntries(new FormData($("searchForm")));
  return {
    categories:selectedValues("searchCategories"),
    name:String(formData.NameKeyword||"").trim().toLowerCase(),
    budgets:selectedValues("searchBudgets"),
    country:$("searchCountry").value,
    region:currentRegionValue("search"),
    atmospheres:selectedValues("searchAtmospheres"),
    parkingLevels:selectedValues("searchParkingLevels"),
    stationDistances:selectedValues("searchStationDistances"),
    party:selectedValues("searchPartySizes"),
    time:selectedValues("searchTimeSlots")
  };
}
function intersects(a=[],b=[]){ const set=new Set(a||[]); return (b||[]).some(x=>set.has(x)); }
function hardMatch(p,c){
  if(c.name && !String(p.PlaceName||"").toLowerCase().includes(c.name)) return false;
  if(c.categories.length && !intersects(p.Categories,c.categories)) return false;
  if(c.budgets.length && !intersects(p.BudgetRanges,c.budgets)) return false;
  if(c.country && p.CountryCode && p.CountryCode!==c.country) return false;
  if(c.region && p.RegionText!==c.region) return false;
  return true;
}
function preferenceScore(p,c){
  let score=0, possible=0, hits=[];
  if(c.atmospheres.length){ possible+=2; if(intersects(p.Atmospheres,c.atmospheres)){score+=2;hits.push("氣氛");} }
  if(c.parkingLevels.length){ possible+=2; if(intersects(p.ParkingLevels,c.parkingLevels)){score+=2;hits.push("停車");} }
  if(c.stationDistances.length){ possible+=2; if(intersects(p.StationDistanceLevels,c.stationDistances)){score+=2;hits.push("車站距離");} }
  if(c.party.length){ possible+=2; if(intersects(p.PartySizes,c.party)){score+=2;hits.push("人數");} }
  if(c.time.length){ possible+=2; if(intersects(p.TimeSlotsV2,c.time)){score+=2;hits.push("時段");} }
  return {score,possible,hits};
}
async function doSearch(e){
  if(e?.preventDefault) e.preventDefault();
  if(!currentUser) return;
  if(searchScope==="public") await loadPublicPlaces();
  const source=searchScope==="mine"?myPlaces:publicPlaces;
  const c=searchCriteria();
  const rows=source.filter(p=>hardMatch(p,c)).map(p=>({...p,_match:preferenceScore(p,c)}))
    .sort((a,b)=>b._match.score-a._match.score || new Date(b.UpdatedAt||0)-new Date(a.UpdatedAt||0));
  renderPlaces(rows,"searchResults",{publicMode:searchScope==="public",showMatch:true});
  $("resultCount").textContent=`${rows.length} 筆`;
}
function clearSearch(){
  $("searchForm").reset(); $("searchCountry").value="TW"; updateRegionUI("search");
  ["searchCategories","searchBudgets","searchAtmospheres","searchParkingLevels","searchStationDistances","searchPartySizes","searchTimeSlots"].forEach(id=>setSelectedValues(id,[]));
  doSearch();
}
function selectCurrentTimeSlot(){
  const h=new Date().getHours();
  let slot;
  if(h>=5&&h<8) slot="05_08"; else if(h>=8&&h<11) slot="08_11"; else if(h>=11&&h<14) slot="11_14";
  else if(h>=14&&h<17) slot="14_17"; else if(h>=17&&h<21) slot="17_21"; else slot="21_05";
  setSelectedValues("searchTimeSlots",[slot]); doSearch();
}
function renderMineList(){
  const kw=String($("mineKeyword").value||"").trim().toLowerCase();
  const vis=$("visibilityFilter").value;
  const rows=myPlaces.filter(p=>{
    const hay=`${p.PlaceName||""} ${p.RegionText||""}`.toLowerCase();
    if(kw && !hay.includes(kw)) return false;
    if(vis==="public" && !p.IsPublic) return false;
    if(vis==="private" && p.IsPublic) return false;
    return true;
  });
  renderPlaces(rows,"mineList",{publicMode:false,showMatch:false});
}
function renderPlaces(rows,targetId,options={}){
  const target=$(targetId); target.innerHTML="";
  if(!rows.length){
    target.innerHTML=`<div class="card"><h3>目前沒有符合資料</h3><p class="meta">${options.publicMode?"還沒有其他使用者公開且符合條件的地點。":"可以到「新增地點」先記下一個想去的地方。"}</p></div>`;
    return;
  }
  const tpl=$("placeCardTemplate");
  rows.forEach(p=>{
    const node=tpl.content.cloneNode(true);
    node.querySelector("h3").textContent=p.PlaceName||"(未命名)";
    node.querySelector(".meta").textContent=[countryLabel(p.CountryCode),p.RegionText].filter(Boolean).join("｜") || "地區未指定";
    const badge=node.querySelector(".visibility-badge");
    badge.textContent=options.publicMode?"公開分享":(p.IsPublic?"公開":"私人");
    badge.classList.add(options.publicMode||p.IsPublic?"public":"private");
    const chipValues=[
      ...labelsFor(p.Categories,"categories"),...labelsFor(p.BudgetRanges,"budgets"),
      ...labelsFor(p.Atmospheres,"atmospheres"),
      ...labelsFor(p.ParkingLevels,"parkingLevels"),
      ...labelsFor(p.StationDistanceLevels,"stationDistances"),
      ...labelsFor(p.PartySizes,"partySizes"),...labelsFor(p.TimeSlotsV2,"timeSlots")
    ];
    const chipBox=node.querySelector(".chips");
    chipValues.forEach(label=>{const span=document.createElement("span");span.className="chip";span.textContent=label;chipBox.appendChild(span);});
    const note=node.querySelector(".note");
    if(options.publicMode){ note.textContent="此為其他使用者公開分享的地點條件。"; }
    else { note.textContent=p.PersonalNote||"沒有私人備註。"; }
    const match=node.querySelector(".match-line");
    if(options.showMatch && p._match?.possible>0){
      match.classList.remove("hidden");
      match.textContent=p._match.hits.length?`偏好符合：${p._match.hits.join("、")}`:"符合基本條件；偏好條件未完全吻合";
    }
    const maps=node.querySelector(".maps-link");
    if(p.GoogleMapsUrl){maps.href=p.GoogleMapsUrl;maps.classList.remove("hidden");}
    const edit=node.querySelector(".edit-btn"), del=node.querySelector(".delete-btn");
    if(options.publicMode){edit.classList.add("hidden");del.classList.add("hidden");}
    else {edit.addEventListener("click",()=>editPlace(p.PlaceId));del.addEventListener("click",()=>deletePlace(p.PlaceId));}
    target.appendChild(node);
  });
}

init().catch(err=>showToast(err.message||String(err),true));
