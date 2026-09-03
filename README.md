# P106 現在要去哪裡｜NowWhere V1.1 Auth Personal Edition

## 1. 專案定位

P106「現在要去哪裡」是個人化生活經驗喚回系統（Personal Experience Retrieval System）。它的核心不是取代 Google Maps，也不是大眾推薦平台，而是協助使用者在「現在要決定去哪裡」時，喚回自己曾經看過、聽過、心動過、親友提過、但平常容易忘記的吃喝玩樂地點。

本版已由無登入原型升級為登入個人版。每位使用者使用 Email + Password 登入後，只能讀寫自己的地點、感受、同行者與今日候選。

## 2. 版本資訊

- 專案編號：P106
- 中文名稱：現在要去哪裡
- 英文標題：NowWhere / Personal Experience Retrieval System
- 版本：V1.1 Auth Personal Edition
- 前端：GitHub Pages 靜態網站
- 後端：Supabase Database + Supabase Auth
- AI：本版暫停 AI 功能，不需要 OpenAI API key
- ZIP 命名：ASCII safe，避免中文 ZIP 檔名造成解壓縮異常

## 3. 風格

本版採「日式文青系 × 台灣公共服務風」：

- 米白、綠、灰藍等柔和色系
- 卡片式資訊呈現
- 介面語言偏生活化
- 功能結構偏公共服務清楚導引
- 不使用過度科技感或遊戲化視覺

## 4. 核心功能

### 4.1 Email + Password 登入

- 註冊帳號
- 登入
- 登出
- 顯示目前登入者 email
- 未登入時無法使用主要功能

### 4.2 現在要去哪裡

使用者可輸入：

- 目前地區
- 可用時間
- 同行者
- 想做的活動
- 限制條件

系統會從使用者自己的收藏中找出符合情境的候選地點。

### 4.3 快速記一下

平常看到或聽到某個想去的地方時，可快速記錄：

- 地點名稱
- 地區
- 路線／地理觸發
- 類型
- 狀態
- 意願
- 誰提過
- 適合時間
- 什麼時候要想起它
- 個人備註
- Google Maps 連結
- 來源網址
- 預算、氣氛、停車、預約等輔助資訊

### 4.4 我的收藏

- 搜尋自己的收藏
- 依狀態篩選
- 查看地點卡片
- 編輯收藏
- 刪除收藏
- 加入今日候選
- 開啟 Google Maps

### 4.5 待整理

顯示資料不完整的收藏，例如缺少：

- 地區
- 觸發條件
- 個人備註

### 4.6 同行者／親友偏好

可建立：

- 家人
- 朋友
- 學生
- 外賓
- 其他同行者

並記錄喜好與避免條件，例如看海、甜點、不想排隊、不喜歡太吵。

## 5. 資料分層設計

本版採「個人地點庫」方案。

原本的共同地點概念保留在 `TblP106Places` 這張主表，但每筆地點都加上 `UserId`，因此實際上是每個人的個人地點庫。這可避免不同使用者對同一地點的感受互相污染。

## 6. 主要資料表

- `TblP106Places`：個人地點主檔與個人感受整合表
- `TblP106Companions`：個人同行者／親友偏好
- `TblP106Sources`：來源紀錄
- `TblP106TodayCandidates`：今日候選清單
- `TblP106UserPlaceNotes`：舊版相容用個人備註表；本版會清空舊個人感受資料

## 7. 安全性修正

本版針對 Supabase linter 警告做以下修正：

1. 移除 P106 舊有匿名全開 RLS policies。
2. 不再建立 anon 可讀寫的 P106 資料表政策。
3. P106 個人表改為 authenticated + `UserId = auth.uid()`。
4. 移除舊版 `P106AddPlace` 與 `P106SearchPlaces` RPC function。
5. `P106SetUpdatedAt` 使用 `SECURITY INVOKER` 並固定 `search_path`。
6. 本版暫停 AI Edge Function，避免匿名消耗 AI API 額度。

## 8. 部署檔案

- `index.html`：主畫面
- `css/style.css`：視覺樣式
- `js/app.js`：前端邏輯
- `config.sample.js`：Supabase 設定範本
- `sql/P106_V1_1_Auth_Personal_schema.sql`：資料庫與 RLS SQL
- `docs/DEPLOYMENT.md`：部署步驟
- `docs/SECURITY_NOTES.md`：安全修正說明
- `functions/AI_DISABLED_IN_V1_1.txt`：AI 暫停說明
- `CHANGELOG.md`：版本變更紀錄
- `FILE_MANIFEST.txt`：檔案清單

## 9. 重要限制

- 本版不含 AI 整理功能。
- 本版不串接 Google Maps API，只保留 Google Maps URL。
- 本版不做多人共享。
- 本版不是公開推薦平台；資料以個人登入後私有使用為主。
- 舊的 `TblP106Places` 資料若沒有 `UserId`，會被保留但不會被任何使用者看見，除非手動指定 owner。
