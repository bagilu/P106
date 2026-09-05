-- P106 NowWhere V2.0 Migration
-- From: V1.1.1 Auth Personal SQLFIX
-- Scope: ONLY public."TblP106Places" and P106-prefixed database objects.
-- Strategy: additive migration; legacy columns/data are preserved.
-- IMPORTANT: This migration does not truncate or delete existing P106 business data.

begin;

alter table public."TblP106Places" add column if not exists "Categories" text[] not null default '{}';
alter table public."TblP106Places" add column if not exists "BudgetRanges" text[] not null default '{}';
alter table public."TblP106Places" add column if not exists "CountryCode" text not null default 'TW';
alter table public."TblP106Places" add column if not exists "RegionText" text;
alter table public."TblP106Places" add column if not exists "Atmospheres" text[] not null default '{}';
alter table public."TblP106Places" add column if not exists "ParkingConvenient" boolean;
alter table public."TblP106Places" add column if not exists "NearStation" boolean;
alter table public."TblP106Places" add column if not exists "PartySizes" text[] not null default '{}';
alter table public."TblP106Places" add column if not exists "TimeSlotsV2" text[] not null default '{}';
alter table public."TblP106Places" add column if not exists "IsPublic" boolean not null default false;

create index if not exists "IdxP106PlacesUserUpdatedV2"
  on public."TblP106Places" ("UserId","UpdatedAt" desc);
create index if not exists "IdxP106PlacesPublicUpdatedV2"
  on public."TblP106Places" ("IsPublic","UpdatedAt" desc)
  where "IsPublic" = true;
create index if not exists "IdxP106PlacesCategoriesV2"
  on public."TblP106Places" using gin ("Categories");
create index if not exists "IdxP106PlacesBudgetsV2"
  on public."TblP106Places" using gin ("BudgetRanges");
create index if not exists "IdxP106PlacesAtmospheresV2"
  on public."TblP106Places" using gin ("Atmospheres");

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

create policy "P106 V2 authenticated select own places"
on public."TblP106Places"
for select to authenticated
using ("UserId" = auth.uid());

create policy "P106 V2 authenticated insert own places"
on public."TblP106Places"
for insert to authenticated
with check ("UserId" = auth.uid());

create policy "P106 V2 authenticated update own places"
on public."TblP106Places"
for update to authenticated
using ("UserId" = auth.uid())
with check ("UserId" = auth.uid());

create policy "P106 V2 authenticated delete own places"
on public."TblP106Places"
for delete to authenticated
using ("UserId" = auth.uid());

-- Public sharing is intentionally NOT implemented as an RLS SELECT policy on the base table,
-- because that would expose private columns such as UserId and PersonalNote.
-- Instead, this authenticated-only SECURITY DEFINER function returns a safe projection.

create or replace function public."P106SearchPublicPlaces"()
returns table(
  "PlaceId" uuid,
  "PlaceName" text,
  "Categories" text[],
  "BudgetRanges" text[],
  "CountryCode" text,
  "RegionText" text,
  "Atmospheres" text[],
  "ParkingConvenient" boolean,
  "NearStation" boolean,
  "PartySizes" text[],
  "TimeSlotsV2" text[],
  "GoogleMapsUrl" text,
  "IsPublic" boolean,
  "CreatedAt" timestamptz,
  "UpdatedAt" timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  return query
  select
    p."PlaceId", p."PlaceName", p."Categories", p."BudgetRanges",
    p."CountryCode", p."RegionText", p."Atmospheres",
    p."ParkingConvenient", p."NearStation", p."PartySizes",
    p."TimeSlotsV2", p."GoogleMapsUrl", p."IsPublic",
    p."CreatedAt", p."UpdatedAt"
  from public."TblP106Places" p
  where p."IsPublic" = true
    and p."IsActive" = true
    and p."UserId" <> auth.uid()
  order by p."UpdatedAt" desc;
end;
$$;

revoke all on function public."P106SearchPublicPlaces"() from public;
revoke all on function public."P106SearchPublicPlaces"() from anon;
grant execute on function public."P106SearchPublicPlaces"() to authenticated;

revoke all on table public."TblP106Places" from anon;
grant select, insert, update, delete on table public."TblP106Places" to authenticated;

commit;
