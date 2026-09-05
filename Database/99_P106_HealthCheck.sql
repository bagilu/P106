-- P106 V2 health check. Read-only and P106-specific.
select
  c.relname as "P106Object",
  c.relrowsecurity as "RLS",
  c.relforcerowsecurity as "ForceRLS"
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public'
  and c.relname='TblP106Places';

select column_name,data_type,is_nullable,column_default
from information_schema.columns
where table_schema='public' and table_name='TblP106Places'
  and column_name in ('PlaceId','UserId','PlaceName','Categories','BudgetRanges','CountryCode','RegionText','Atmospheres','ParkingConvenient','NearStation','ParkingLevels','StationDistanceLevels','PartySizes','TimeSlotsV2','PersonalNote','GoogleMapsUrl','IsPublic','CreatedAt','UpdatedAt')
order by ordinal_position;

select policyname,cmd,roles,qual,with_check
from pg_policies
where schemaname='public' and tablename='TblP106Places'
order by policyname;

select
  p.proname,
  p.prosecdef as "SecurityDefiner",
  coalesce(array_to_string(p.proconfig,','),'') as "FunctionConfig"
from pg_proc p
join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('P106SetUpdatedAt','P106SearchPublicPlaces')
order by p.proname;

select
  has_table_privilege('anon','public."TblP106Places"','select') as "AnonSelect",
  has_table_privilege('authenticated','public."TblP106Places"','select') as "AuthenticatedSelect",
  has_function_privilege('anon','public."P106SearchPublicPlaces"()','execute') as "AnonPublicSearchExecute",
  has_function_privilege('authenticated','public."P106SearchPublicPlaces"()','execute') as "AuthenticatedPublicSearchExecute";
