-- P106 SBI-P-SDS v3.7 Health Check
-- Read-only catalog checks. P106 only.

-- 1. RLS status.
select c.relname as object_name,
       c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public'
  and c.relname like 'TblP106%'
order by c.relname;

-- 2. Direct table grants should be absent for anon/authenticated.
select
  has_table_privilege('anon','public."TblP106Places"','select') as anon_select,
  has_table_privilege('anon','public."TblP106Places"','insert') as anon_insert,
  has_table_privilege('authenticated','public."TblP106Places"','select') as auth_select,
  has_table_privilege('authenticated','public."TblP106Places"','insert') as auth_insert,
  has_table_privilege('authenticated','public."TblP106Places"','update') as auth_update,
  has_table_privilege('authenticated','public."TblP106Places"','delete') as auth_delete;

-- 3. P106 RPC inventory / security mode / search_path.
select p.proname,
       p.prosecdef as security_definer,
       coalesce(array_to_string(p.proconfig,','),'') as config
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname like 'P106%'
order by p.proname;

-- 4. EXECUTE privileges.
select
  has_function_privilege('anon','public."P106_ListMyPlaces"()','execute') as anon_list_my_places,
  has_function_privilege('authenticated','public."P106_ListMyPlaces"()','execute') as auth_list_my_places,
  has_function_privilege('anon','public."P106SearchPublicPlaces"()','execute') as anon_search_public,
  has_function_privilege('authenticated','public."P106SearchPublicPlaces"()','execute') as auth_search_public,
  has_function_privilege('anon','public."P106_CreatePlace"(jsonb)','execute') as anon_create,
  has_function_privilege('authenticated','public."P106_CreatePlace"(jsonb)','execute') as auth_create,
  has_function_privilege('anon','public."P106_UpdatePlace"(uuid,jsonb)','execute') as anon_update,
  has_function_privilege('authenticated','public."P106_UpdatePlace"(uuid,jsonb)','execute') as auth_update,
  has_function_privilege('anon','public."P106_DeletePlace"(uuid)','execute') as anon_delete,
  has_function_privilege('authenticated','public."P106_DeletePlace"(uuid)','execute') as auth_delete;
