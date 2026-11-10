-- P106 SBI-P-SDS v3.7 RPC-Only Migration
-- Date: 2026-11-10
-- Scope: P106 objects only.
-- IMPORTANT: Run in Supabase SQL Editor before switching production frontend to js/app.rpc-v37.js.
-- This migration preserves existing data and enables RPC-only frontend access.

begin;

-- RLS stays enabled and forced.
alter table public."TblP106Places" enable row level security;
alter table public."TblP106Places" force row level security;

-- Existing direct table policies may remain as defense in depth,
-- but direct Data API access is removed by table grants below.

-- 1) List current user's places.
create or replace function public."P106_ListMyPlaces"()
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
  "PersonalNote" text,
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
    p."PersonalNote", p."GoogleMapsUrl", p."IsPublic",
    p."CreatedAt", p."UpdatedAt"
  from public."TblP106Places" p
  where p."UserId" = auth.uid()
    and p."IsActive" = true
  order by p."UpdatedAt" desc;
end;
$$;

-- 2) Public discovery: least-data projection only.
drop function if exists public."P106SearchPublicPlaces"();

create function public."P106SearchPublicPlaces"()
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

-- 3) Create place.
create or replace function public."P106_CreatePlace"(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
  v_name text := nullif(btrim(payload->>'PlaceName'), '');
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if v_name is null then
    raise exception 'PlaceName is required';
  end if;

  insert into public."TblP106Places"(
    "UserId","PlaceName","Categories","BudgetRanges","CountryCode","RegionText",
    "Atmospheres","ParkingLevels","StationDistanceLevels","PartySizes","TimeSlotsV2",
    "PersonalNote","GoogleMapsUrl","IsPublic"
  )
  values(
    v_uid,
    v_name,
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'Categories','[]'::jsonb))), '{}'),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'BudgetRanges','[]'::jsonb))), '{}'),
    coalesce(nullif(payload->>'CountryCode',''),'TW'),
    nullif(payload->>'RegionText',''),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'Atmospheres','[]'::jsonb))), '{}'),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'ParkingLevels','[]'::jsonb))), '{}'),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'StationDistanceLevels','[]'::jsonb))), '{}'),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'PartySizes','[]'::jsonb))), '{}'),
    coalesce(array(select jsonb_array_elements_text(coalesce(payload->'TimeSlotsV2','[]'::jsonb))), '{}'),
    nullif(payload->>'PersonalNote',''),
    nullif(payload->>'GoogleMapsUrl',''),
    coalesce((payload->>'IsPublic')::boolean,false)
  )
  returning "PlaceId" into v_id;

  return v_id;
end;
$$;

-- 4) Update own place only.
create or replace function public."P106_UpdatePlace"(place_id uuid, payload jsonb)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := nullif(btrim(payload->>'PlaceName'), '');
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if place_id is null then
    raise exception 'PlaceId is required';
  end if;
  if v_name is null then
    raise exception 'PlaceName is required';
  end if;

  update public."TblP106Places"
  set
    "PlaceName" = v_name,
    "Categories" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'Categories','[]'::jsonb))), '{}'),
    "BudgetRanges" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'BudgetRanges','[]'::jsonb))), '{}'),
    "CountryCode" = coalesce(nullif(payload->>'CountryCode',''),'TW'),
    "RegionText" = nullif(payload->>'RegionText',''),
    "Atmospheres" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'Atmospheres','[]'::jsonb))), '{}'),
    "ParkingLevels" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'ParkingLevels','[]'::jsonb))), '{}'),
    "StationDistanceLevels" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'StationDistanceLevels','[]'::jsonb))), '{}'),
    "PartySizes" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'PartySizes','[]'::jsonb))), '{}'),
    "TimeSlotsV2" = coalesce(array(select jsonb_array_elements_text(coalesce(payload->'TimeSlotsV2','[]'::jsonb))), '{}'),
    "PersonalNote" = nullif(payload->>'PersonalNote',''),
    "GoogleMapsUrl" = nullif(payload->>'GoogleMapsUrl',''),
    "IsPublic" = coalesce((payload->>'IsPublic')::boolean,false)
  where "PlaceId" = place_id
    and "UserId" = v_uid
    and "IsActive" = true;

  return found;
end;
$$;

-- 5) Delete own place only.
create or replace function public."P106_DeletePlace"(place_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if place_id is null then
    raise exception 'PlaceId is required';
  end if;

  delete from public."TblP106Places"
  where "PlaceId" = place_id
    and "UserId" = v_uid;

  return found;
end;
$$;

-- No direct table access from frontend roles.
revoke all on table public."TblP106Places" from anon;
revoke all on table public."TblP106Places" from authenticated;

-- RPC execute: authenticated only.
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

-- Trigger helper must not be exposed as a client RPC.
revoke all on function public."P106SetUpdatedAt"() from public, anon, authenticated;

commit;
