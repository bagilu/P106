# P106 V1.1 安全修正說明

本版目的之一是消除 P106 在 Supabase linter 中出現的主要安全警告。

## 1. 移除匿名全開政策

舊版無登入原型為了方便測試，曾建立 anon 可 `ALL` 或 `INSERT/UPDATE/DELETE` 的 RLS policy。本版 SQL 會先刪除所有 `TblP106%` 表上的既有 policy，然後重新建立只給 `authenticated` 使用者的私有 policy。

## 2. 個人資料私有化

所有主要資料表使用：

```sql
"UserId" = auth.uid()
```

因此每位登入者只能讀寫自己的資料。

## 3. 移除 P106AddPlace 與 P106SearchPlaces

舊版 RPC function 可能造成：

- Function Search Path Mutable
- Public Can Execute SECURITY DEFINER Function

本版改由前端直接操作資料表，並由 RLS 控制權限。因此不再需要這些 RPC function。

## 4. search_path 固定

本版仍保留更新時間 trigger function：

```sql
P106SetUpdatedAt()
```

其設定為：

```sql
security invoker
set search_path = public, pg_temp
```

避免 role mutable search_path 警告。

## 5. AI 暫停

本版移除 AI 整理入口，不部署 Edge Function，避免未登入者或外部呼叫者消耗 API 額度。

## 6. 注意

Supabase linter 可能仍會顯示其他 P 系列專案的警告。本版只處理 P106，不處理 P01、P02、P03、P102、P112 或其他專案。
