# P106 V1.1 Auth Personal Edition 部署步驟

## 1. Supabase：啟用 Auth

1. 進入 Supabase 專案。
2. 開啟 Authentication。
3. 確認 Email provider 已啟用。
4. 本版使用 Email + Password。
5. 若希望註冊後立刻可登入，可在開發測試階段關閉 Email confirmation；若正式使用，建議保留 Email confirmation。

## 2. Supabase：執行 SQL

1. 進入 SQL Editor。
2. 開啟 `sql/P106_V1_1_Auth_Personal_schema.sql`。
3. 全部貼上並執行。
4. 執行後檢查是否建立以下資料表：
   - `TblP106Places`
   - `TblP106Companions`
   - `TblP106Sources`
   - `TblP106TodayCandidates`
   - `TblP106UserPlaceNotes`

## 3. Supabase：確認 RLS

請確認上述 P106 資料表均已啟用 RLS。

本版不建立 anon 讀寫政策。前端使用者必須登入，並由 RLS 限制每位使用者只能讀寫自己的資料。

## 4. Supabase：處理舊資料

本 SQL 會保留 `TblP106Places` 的舊地點主檔資料，但會清空：

- `TblP106UserPlaceNotes`
- `TblP106TodayCandidates`
- `TblP106Sources`
- `TblP106Companions`

若舊 `TblP106Places` 中有無登入時建立的資料，這些資料的 `UserId` 通常是 `null`。在 V1.1 中，它們會被 RLS 隱藏。若要指定給某位使用者，請查出該使用者在 `auth.users` 裡的 id，然後執行：

```sql
update public."TblP106Places"
set "UserId" = '請替換成該使用者 UUID'
where "UserId" is null;
```

## 5. 前端：設定 config.js

1. 將 `config.sample.js` 複製一份並命名為 `config.js`。
2. 填入 Supabase Project URL 與 anon key。

範例：

```js
window.P106_CONFIG = {
  SUPABASE_URL: 'https://xxxx.supabase.co',
  SUPABASE_ANON_KEY: '你的 anon key'
};
```

## 6. GitHub Pages 部署

1. 建立 GitHub repository。
2. 上傳整個 `P106_NowWhere_V1_1_Auth_Personal` 資料夾內的檔案。
3. 確認包含 `config.js`。
4. 到 repository 的 Settings → Pages。
5. 選擇部署 branch，例如 `main` 與 root。
6. 等待 GitHub Pages 產生網址。

## 7. Supabase Auth Site URL 與 Redirect URLs

若使用 Email confirmation 或之後加入 Magic Link，請到 Supabase：

Authentication → URL Configuration

設定：

- Site URL：你的 GitHub Pages 網址
- Redirect URLs：你的 GitHub Pages 網址

Email + Password 一般登入不一定需要 redirect，但正式部署建議設定。

## 8. 測試流程

1. 開啟 GitHub Pages 網址。
2. 註冊一個測試帳號。
3. 登入。
4. 新增同行者。
5. 到「快速記一下」新增一筆地點。
6. 到「我的收藏」確認有資料。
7. 登出。
8. 註冊另一個帳號。
9. 確認看不到第一個帳號的資料。

## 9. AI 功能

本版暫停 AI 功能，不需要設定 OpenAI API key，也不需要部署 Edge Function。

若未來恢復 AI 功能，應採：

- 僅登入者可呼叫 Edge Function
- Edge Function 檢查 JWT
- OpenAI API key 放 Supabase Secrets
- 前端不暴露 OpenAI API key
