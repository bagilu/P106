# P106 部署步驟

本文件說明如何將 P106「現在要去哪裡」部署到 GitHub Pages 與 Supabase。

---

## 一、建立 Supabase 專案

1. 登入 Supabase。
2. 建立新 Project。
3. 進入 Project 後，打開 **SQL Editor**。
4. 開啟本專案檔案：`sql/P106_schema.sql`。
5. 將 SQL 全部複製貼上並執行。
6. 確認左側 Table Editor 已出現以下資料表：
   - `TblP106Places`
   - `TblP106UserPlaceNotes`
   - `TblP106Sources`
   - `TblP106Companions`
   - `TblP106TodayCandidates`

---

## 二、取得 Supabase URL 與 anon key

1. Supabase Dashboard 進入 **Project Settings**。
2. 進入 **API**。
3. 複製：
   - Project URL
   - anon public key

---

## 三、建立 config.js

1. 在專案根目錄複製：

```text
config.sample.js → config.js
```

2. 修改 `config.js`：

```javascript
window.P106_SUPABASE_CONFIG = {
  url: 'https://你的project.supabase.co',
  anonKey: '你的anon key',
  edgeFunctionBaseUrl: 'https://你的project.functions.supabase.co'
};
```

3. 之後更新新版 ZIP 時，請保留自己的 `config.js`，不要覆蓋。

---

## 四、部署到 GitHub Pages

1. 建立 GitHub repository。
2. 將本專案資料夾內檔案上傳到 repository。
3. 確認根目錄包含：
   - `index.html`
   - `config.js`
   - `css/style.css`
   - `js/app.js`
4. 進入 GitHub repository 的 **Settings**。
5. 選擇 **Pages**。
6. Source 選擇 main branch / root。
7. 儲存後等待 GitHub Pages 產生網址。

---

## 五、部署 AI Edge Function：P106AnalyzeInput，可選

若暫時不使用 AI 功能，可以略過此步驟。系統仍可手動輸入與查詢。

### 5.1 建立 Function

1. Supabase Dashboard 進入 **Edge Functions**。
2. 選擇建立新 Function。
3. Function 名稱請使用：

```text
P106AnalyzeInput
```

4. 將 `functions/P106AnalyzeInput/index.ts` 內容完整貼上。
5. 儲存或部署。

### 5.2 設定 Secrets

進入 Supabase Edge Functions 的 Secrets 或 Project Settings 中設定：

```text
OPENAI_API_KEY=你的 OpenAI API key
OPENAI_MODEL=gpt-4.1-mini
```

`OPENAI_MODEL` 可省略，預設為 `gpt-4.1-mini`。

---

## 六、測試流程

### 6.1 手動輸入測試

1. 打開網站。
2. 進入「快速記一下」。
3. 新增一筆地點，例如：
   - 地點名稱：200K 附近海灘
   - 地區／路線：台11線
   - 類型：景點
   - 誰提過：A
   - 何時想起：台11線、有三小時、天氣好
4. 儲存後到「我的收藏」確認。

### 6.2 情境喚回測試

1. 回到「現在要去哪裡」。
2. 輸入：
   - 我現在在哪裡：台11線
   - 我有多少時間：3小時
   - 我跟誰一起：A
   - 現在想做什麼：看海
3. 按「現在要去哪裡？」。
4. 應看到剛才新增的地點。

### 6.3 AI 整理測試

1. 進入「AI 幫我整理」。
2. 貼上一段部落格或朋友推薦文字。
3. 按「產生欄位建議」。
4. 修改欄位後按「確認儲存」。

---

## 七、正式使用前建議

本版預設為教學展示版，RLS 允許 anon 讀寫。若要正式多人使用，建議：

1. 加入 Supabase Auth。
2. 資料表加上 `user_id`。
3. RLS 改成使用者只能管理自己的個人感受資料。
4. 共同地點主檔可開放讀取，但新增與修改需記錄使用者。
5. AI 來源文字若涉及著作權，建議只儲存摘要與來源網址，不長期保存全文。
