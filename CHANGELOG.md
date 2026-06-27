# CHANGELOG

## 2026-06-27 - V1.0.1

### Fixed
- 修正快速新增、AI確認儲存、同行者新增等非同步表單送出後，`event.currentTarget` 可能變成 `null`，導致 `Cannot read properties of null (reading 'reset')` 的問題。
- 做法：在 `await` 前先把表單物件保存為 `const form = e.currentTarget;`，後續改用 `form.reset()`。
