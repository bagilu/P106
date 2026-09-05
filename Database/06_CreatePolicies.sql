drop policy if exists "P106 V2 authenticated select own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated insert own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated update own places" on public."TblP106Places";
drop policy if exists "P106 V2 authenticated delete own places" on public."TblP106Places";

create policy "P106 V2 authenticated select own places"
on public."TblP106Places" for select to authenticated
using ("UserId"=auth.uid());

create policy "P106 V2 authenticated insert own places"
on public."TblP106Places" for insert to authenticated
with check ("UserId"=auth.uid());

create policy "P106 V2 authenticated update own places"
on public."TblP106Places" for update to authenticated
using ("UserId"=auth.uid()) with check ("UserId"=auth.uid());

create policy "P106 V2 authenticated delete own places"
on public."TblP106Places" for delete to authenticated
using ("UserId"=auth.uid());
