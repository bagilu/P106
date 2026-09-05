-- P106 V2 functions only.
create or replace function public."P106SetUpdatedAt"()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new."UpdatedAt" = now();
  return new;
end;
$$;

drop trigger if exists "P106SetUpdatedAt_TblP106Places" on public."TblP106Places";
create trigger "P106SetUpdatedAt_TblP106Places"
before update on public."TblP106Places"
for each row execute function public."P106SetUpdatedAt"();

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
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return query
  select p."PlaceId",p."PlaceName",p."Categories",p."BudgetRanges",p."CountryCode",p."RegionText",
         p."Atmospheres",p."ParkingLevels",p."StationDistanceLevels",p."PartySizes",p."TimeSlotsV2",
         p."GoogleMapsUrl",p."IsPublic",p."CreatedAt",p."UpdatedAt"
  from public."TblP106Places" p
  where p."IsPublic"=true and p."IsActive"=true and p."UserId"<>auth.uid()
  order by p."UpdatedAt" desc;
end;
$$;
