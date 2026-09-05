-- P106 V2 permissions repair. Safe to rerun. P106 objects only.
begin;
alter table public."TblP106Places" enable row level security;
alter table public."TblP106Places" force row level security;

drop policy if exists "P106 authenticated select own places" on public."TblP106Places";
drop policy if exists "P106 authenticated insert own places" on public."TblP106Places";
drop policy if exists "P106 authenticated update own places" on public."TblP106Places";
drop policy if exists "P106 authenticated delete own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated select own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated insert own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated update own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated delete own places" on public."TblP106Places";

create policy "P106 V2 authenticated select own places" on public."TblP106Places" for select to authenticated using ("UserId"=auth.uid());
create policy "P106 V2 authenticated insert own places" on public."TblP106Places" for insert to authenticated with check ("UserId"=auth.uid());
create policy "P106 V2 authenticated update own places" on public."TblP106Places" for update to authenticated using ("UserId"=auth.uid()) with check ("UserId"=auth.uid());
create policy "P106 V2 authenticated delete own places" on public."TblP106Places" for delete to authenticated using ("UserId"=auth.uid());

revoke all on table public."TblP106Places" from anon;
grant select,insert,update,delete on table public."TblP106Places" to authenticated;

revoke all on function public."P106SearchPublicPlaces"() from public;
revoke all on function public."P106SearchPublicPlaces"() from anon;
grant execute on function public."P106SearchPublicPlaces"() to authenticated;
commit;
