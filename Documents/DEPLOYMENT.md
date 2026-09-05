# P106 V2 部署步驟

## A. 從目前 V1.1.1 升級
1. 先備份 Supabase。
2. 執行：`Database/Migrations/P106_V2_1_Migration.sql`
3. 不要執行 fresh-install 的 01–08 檔案。
4. GitHub 更新：
   - `index.html`
   - `css/style.css`
   - `js/app.js`
5. **保留目前正式 `config.js`。ZIP 不含正式 config.js。**
6. 若需要重新建立設定，使用 `config.sample.js` 複製成 `config.js`。

## B. Auth Redirect
Supabase → Authentication → URL Configuration：
- Site URL：設定為 P106 GitHub Pages 實際網址
- Additional Redirect URLs：加入 P106 GitHub Pages 網址與需要的 wildcard

前端註冊已使用：
`emailRedirectTo = window.location.origin + window.location.pathname`

## C. 必做 A/B 測試
### 私人
1. A 登入，新建地點，保持「不公開」。
2. B 登入，切到「公開地點」。
3. B 不得看到 A 的私人地點。

### 公開
1. A 將一筆地點改成「公開」。
2. B 登入「公開地點」。
3. B 應能查到地點名稱與分享欄位。
4. B 不得看到 A 的私人備註、UserId。
5. B 不得編輯或刪除 A 的地點。

### 擁有者
1. A 在「我的地點」應看到自己的私人＋公開地點。
2. A 可以修改公開狀態。
3. A 可以編輯與刪除自己的資料。

## D. 健康檢查
執行 `Database/99_P106_HealthCheck.sql`。
再跑 Supabase Security Advisor / linter，只處理 P106 項目。

## E. 回復權限
若 P106 權限異常，執行：
`Database/90_P106_Permissions.sql`

## F. 注意
此版公開 =「其他已登入 P106 使用者可查詢」，不是未登入全網公開。

## V2.1 升級注意
若目前已成功部署 V2.0，只執行 `Database/Migrations/P106_V2_1_Migration.sql`，不要重跑 V2.0 migration。
