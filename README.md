# P106 現在要去哪裡｜NowWhere V2.1 Parking & Station Ranges Candidate

## 定位
P106 是情境式生活經驗喚回系統。V2 將新增流程改成「未來真的會拿來查詢的條件」，並加入私人／公開兩種可見性。

## V2 核心欄位
- 食／住／景：可複選
- 名稱：文字，支援模糊查詢
- 大致預算：8 個級距，可複選
- 地點：國家＋第二層行政區；台灣為預設
- 氣氛：奢華、高雅、文青、簡陋、喧嘩、安靜，可複選
- 停車：方便／普通／不方便，可複選
- 距離車站：近／普通／遠，可複選
- 適合人數：1、2、3–4、5–8、9+，可複選
- 適合時段：05–08、08–11、11–14、14–17、17–21、21–05，可複選
- 私人備註：選填
- 是否公開：預設不公開

## 公開資料的安全模型
`IsPublic = false`：只有擁有者登入後可讀寫。

`IsPublic = true`：其他已登入 P106 的使用者可透過 `P106SearchPublicPlaces()` 查詢安全欄位。

**不直接建立 `IsPublic=true` 的 base-table SELECT policy。**
這樣可避免把 `UserId`、`PersonalNote` 等私人欄位一併暴露給其他使用者。

V2 公開查詢不提供：
- UserId
- Email
- PersonalNote
- 其他舊版私人欄位

## 查詢分流
「現在要去哪裡」頁面分為：
1. 我的地點
2. 公開地點

基本條件（類型、名稱、預算、地點）負責篩選；氣氛、交通、人數與時段作為偏好排序。

## 舊資料
V2 migration 採 additive migration，不刪除 V1.1.1 舊資料與舊欄位。既有地點的 V2 新欄位會先是預設值，之後可逐筆編輯補上。

## 部署
既有 P106 V1.1.1：
1. 備份資料庫。
2. 執行 `Database/Migrations/P106_V2_0_Migration.sql`。
3. 更新 `index.html`、`css/style.css`、`js/app.js`。
4. **保留線上既有 `config.js`，ZIP 內不提供正式 config.js。**
5. Supabase Auth URL Configuration 設定正確的 GitHub Pages URL。
6. 用 A/B 兩帳號做 RLS 與公開分享測試。

## AI
V2 仍不啟用 AI，不需要 OpenAI API key 或 Edge Function。

## 版本狀態
本 ZIP 是 **V2.0 Candidate**。需在實際 Supabase 與 GitHub Pages 上完成 A/B 帳號驗證後，才建議標記 Stable。

## V2.1 交通條件更新
- `ParkingLevels text[]`：CONVENIENT / NORMAL / INCONVENIENT
- `StationDistanceLevels text[]`：NEAR / NORMAL / FAR
- 舊 `ParkingConvenient`、`NearStation` 欄位暫時保留，不再由 V2.1 前端使用。
