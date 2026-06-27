# P106 現在要去哪裡

**英文標題：** Personal Experience Retrieval System  
**系統定位：** 情境式生活經驗喚回系統  
**技術架構：** GitHub Pages 靜態網站 + Supabase 資料庫 + 可選 Supabase Edge Function AI 欄位建議

---

## 1. 專案核心

P106 的問題不是「不知道哪裡好玩」，而是：平常曾經看到、聽到、想到很多想去的地方，但真正到了吃飯、旅行、有空檔或跟親友出門時，卻想不起來。

因此本系統的核心不是大眾推薦，而是：

> 把自己與小群體曾經心動、提過、想去、順路可去的地方，在適合情境中重新喚回。

---

## 2. 主要使用情境

1. 平常看到餐廳、景點、活動時，快速記下來。
2. 聽到親友提過某地點時，記錄「誰提過」。
3. 之後人在某個地區、有三小時空檔、或正在規劃路線時，系統協助喚回以前收藏過的候選地點。
4. 選定後可再開啟 Google Maps 確認路線、營業時間與即時資訊。

---

## 3. 視覺風格

本版採用「日式文青系」與「台灣公共服務風」混合：

- 日式文青：米白紙感、淡雅色塊、柔和留白。
- 台灣公共服務：清楚導覽、穩重藍綠、表單與資訊卡明確。

---

## 4. 系統介面

### 4.1 現在要去哪裡

輸入目前情境：

- 我現在在哪裡
- 我有多少時間
- 我跟誰一起
- 現在想做什麼
- 條件限制

系統從資料庫喚回可能合適的地點，並顯示「為什麼出現」。

### 4.2 快速記一下

平常看到或聽到某個地點時，快速輸入：

- 地點名稱
- 地區／路線
- 類型
- 誰提過
- 為什麼想去
- 什麼時候要想起它
- 來源網址
- 狀態

### 4.3 AI 幫我整理

可貼上部落格文字、朋友訊息或網址。系統呼叫 Supabase Edge Function `P106AnalyzeInput` 產生欄位建議。使用者修改確認後才儲存。

若未部署 Edge Function，前端仍可用示範模式產生簡易欄位建議。

### 4.4 我的收藏

查看所有收藏，支援關鍵字與狀態篩選。

### 4.5 待整理

顯示欄位不完整的資料，例如缺少地區、缺少喚回條件或缺少備註。

### 4.6 同行者

記錄親友、學生、外賓等偏好與限制，未來可用於更精準的情境喚回。

---

## 5. 資料表

所有資料表依老師指定，以 `TblP106` 開頭：

| 資料表 | 用途 |
|---|---|
| `TblP106Places` | 共同地點主檔 |
| `TblP106UserPlaceNotes` | 個人感受、喚回條件、情境標籤 |
| `TblP106Sources` | 來源網址、來源文字、AI 摘要與建議 JSON |
| `TblP106Companions` | 同行者偏好與限制 |
| `TblP106TodayCandidates` | 今日候選清單，預留後續使用 |

---

## 6. Function

依指定命名，Function 以 `P106` 開頭：

| Function | 類型 | 用途 |
|---|---|---|
| `P106AddPlace` | PostgreSQL function | 新增地點，供未來 RPC 使用 |
| `P106SearchPlaces` | PostgreSQL function | 基礎情境查詢 |
| `P106AnalyzeInput` | Supabase Edge Function | AI 欄位建議 |

Edge Function 不使用 CLI / npx deploy。本專案提供 `functions/P106AnalyzeInput/index.ts`，可在 Supabase Dashboard 手動建立並貼上。

---

## 7. 檔案結構

```text
P106_現在要去哪裡/
├── index.html
├── config.sample.js
├── css/
│   └── style.css
├── js/
│   └── app.js
├── sql/
│   └── P106_schema.sql
├── functions/
│   └── P106AnalyzeInput/
│       └── index.ts
├── docs/
│   └── DEPLOYMENT.md
└── README.md
```

---

## 8. 注意事項

1. ZIP 只提供 `config.sample.js`，不提供實際 `config.js`。
2. 部署後請自行複製 `config.sample.js` 為 `config.js`。
3. 教學展示版 RLS 允許 anon 讀寫，正式多人使用前應改成登入權限控管。
4. AI 網址讀取可能受網站阻擋，貼上文字的成功率通常高於只貼網址。
