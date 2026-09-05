-- P106 NowWhere V2.1 Migration
-- From: V2.0 Public Sharing Candidate
-- Scope: ONLY public."TblP106Places" and P106-prefixed objects.
-- Additive only: no business data is deleted; old boolean fields are preserved for compatibility.

begin;

alter table public."TblP106Places"
  add column if not exists "ParkingLevels" text[] not null default '{}';

alter table public."TblP106Places"
  add column if not exists "StationDistanceLevels" text[] not null default '{}';

create index if not exists "IdxP106PlacesParkingLevelsV21"
  on public."TblP106Places" using gin ("ParkingLevels");

create index if not exists "IdxP106PlacesStationDistanceV21"
  on public."TblP106Places" using gin ("StationDistanceLevels");

-- Optional best-effort migration of old booleans into V2.1 tags.
update public."TblP106Places"
set "ParkingLevels" = case
  when coalesce(cardinality("ParkingLevels"),0) > 0 then "ParkingLevels"
  when "ParkingConvenient" is true then array['CONVENIENT']::text[]
  when "ParkingConvenient" is false then array['INCONVENIENT']::text[]
  else '{}'::text[]
end
where coalesce(cardinality("ParkingLevels"),0)=0;

update public."TblP106Places"
set "StationDistanceLevels" = case
  when coalesce(cardinality("StationDistanceLevels"),0) > 0 then "StationDistanceLevels"
  when "NearStation" is true then array['NEAR']::text[]
  when "NearStation" is false then array['FAR']::text[]
  else '{}'::text[]
end
where coalesce(cardinality("StationDistanceLevels"),0)=0;

-- Return signature changed in V2.1, so PostgreSQL requires DROP before recreate.
drop function if exists public."P106SearchPublicPlaces"();

create or replace function public."P106SearchPublicPlaces"()
returns table(
  "PlaceId" uuid,
  "PlaceName" text,
  "Categories" text[],
  "BudgetRanges" text[],
  "CountryCode" text,
  "RegionText" text,
  "Atmospheres" text[],
  "ParkingLevels" text[],
  "StationDistanceLevels" text[],
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
    p."ParkingLevels", p."StationDistanceLevels",
    p."PartySizes", p."TimeSlotsV2",
    p."GoogleMapsUrl", p."IsPublic",
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

commit;
