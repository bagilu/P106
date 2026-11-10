-- P106 SBI-P-SDS v3.7 permissions repair
-- Safe to rerun after the v3.7 RPC-only migration. P106 objects only.
begin;

alter table public."TblP106Places" enable row level security;
alter table public."TblP106Places" force row level security;

revoke all on table public."TblP106Places" from anon;
revoke all on table public."TblP106Places" from authenticated;

revoke all on function public."P106_ListMyPlaces"() from public, anon;
revoke all on function public."P106SearchPublicPlaces"() from public, anon;
revoke all on function public."P106_CreatePlace"(jsonb) from public, anon;
revoke all on function public."P106_UpdatePlace"(uuid,jsonb) from public, anon;
revoke all on function public."P106_DeletePlace"(uuid) from public, anon;

grant execute on function public."P106_ListMyPlaces"() to authenticated;
grant execute on function public."P106SearchPublicPlaces"() to authenticated;
grant execute on function public."P106_CreatePlace"(jsonb) to authenticated;
grant execute on function public."P106_UpdatePlace"(uuid,jsonb) to authenticated;
grant execute on function public."P106_DeletePlace"(uuid) to authenticated;

revoke all on function public."P106SetUpdatedAt"() from public, anon, authenticated;

commit;
