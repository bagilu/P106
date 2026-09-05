# P106 V2 Security Notes

## 1. 私人資料
`TblP106Places` 的一般 SELECT policy 仍只有：
`UserId = auth.uid()`

## 2. 公開分享
沒有新增 `using (IsPublic = true)` 的 base-table policy。

原因：若對 authenticated 直接開 base-table public SELECT，其他使用者會同時取得該 row 的 `UserId`、`PersonalNote` 與其他舊版欄位。

V2 改用：
`P106SearchPublicPlaces()`

此函式：
- `SECURITY DEFINER`
- `SET search_path = ''`
- 先檢查 `auth.uid()`
- 只回傳安全欄位
- 排除擁有者自己的資料
- PUBLIC/anon 無 execute
- authenticated 才可 execute

## 3. 前端
每個 P 專案必須有自己的 Auth storageKey。
P106 V2 使用：
`p106-auth-token`

## 4. Config
release ZIP 僅含 `config.sample.js`，不含正式 `config.js`。
