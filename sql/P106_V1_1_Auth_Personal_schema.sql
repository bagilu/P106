-- P106 NowWhere V1.1.1 Auth Personal Edition
-- Scope: Only objects whose names start with TblP106 or P106 are touched.
-- Purpose: Upgrade P106 from anonymous prototype to Supabase Auth personal edition.
-- This version is migration-safe for databases that already ran P106 V1.0/V1.0.1.

create extension if not exists pgcrypto;

-- 1. Remove old P106 overly permissive policies.
do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename like 'TblP106%'
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

-- 2. Drop old P106 RPC functions that caused linter warnings or exposed SECURITY DEFINER entry points.
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('P106AddPlace','P106SearchPlaces')
  loop
    execute 'drop function if exists ' || r.sig || ' cascade';
  end loop;
end $$;

-- 3. Create tables for fresh installs. Existing older tables are upgraded below.
create table if not exists public."TblP106Places" (
  "PlaceId" uuid primary key default gen_random_uuid(),
  "UserId" uuid references auth.users(id) on delete cascade default auth.uid(),
  "PlaceName" text not null,
  "AreaText" text,
  "RouteTag" text,
  "PlaceType" text,
  "AddressText" text,
  "GoogleMapsUrl" text,
  "OfficialUrl" text,
  "SourceUrl" text,
  "VisitStatus" text default '未去',
  "DesireLevel" text default '待確認',
  "MentionedByCompanionId" uuid,
  "TimeTags" text[] default '{}',
  "TriggerTags" text[] default '{}',
  "MoodTags" text[] default '{}',
  "BudgetLevel" text,
  "ParkingNote" text,
  "ReservationNote" text,
  "PersonalNote" text,
  "IsActive" boolean not null default true,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);

create table if not exists public."TblP106Companions" (
  "CompanionId" uuid primary key default gen_random_uuid(),
  "UserId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "CompanionName" text not null,
  "RelationLabel" text,
  "PreferenceTags" text[] default '{}',
  "AvoidanceTags" text[] default '{}',
  "Notes" text,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);

create table if not exists public."TblP106Sources" (
  "SourceId" uuid primary key default gen_random_uuid(),
  "UserId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "PlaceId" uuid,
  "SourceType" text default 'manual',
  "SourceUrl" text,
  "SourceTitle" text,
  "SourceNote" text,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);

create table if not exists public."TblP106TodayCandidates" (
  "CandidateId" uuid primary key default gen_random_uuid(),
  "UserId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "PlaceId" uuid,
  "CandidateDate" date not null default current_date,
  "CandidateStatus" text default '候選',
  "Notes" text,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);

create table if not exists public."TblP106UserPlaceNotes" (
  "NoteId" uuid primary key default gen_random_uuid(),
  "UserId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "PlaceId" uuid,
  "PersonalNote" text,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);

-- 4. Upgrade legacy V1.0 lowercase schema to V1.1 CamelCase schema.
alter table public."TblP106Places" add column if not exists "PlaceId" uuid default gen_random_uuid();
alter table public."TblP106Places" add column if not exists "UserId" uuid references auth.users(id) on delete cascade default auth.uid();
alter table public."TblP106Places" add column if not exists "PlaceName" text;
alter table public."TblP106Places" add column if not exists "AreaText" text;
alter table public."TblP106Places" add column if not exists "RouteTag" text;
alter table public."TblP106Places" add column if not exists "PlaceType" text;
alter table public."TblP106Places" add column if not exists "AddressText" text;
alter table public."TblP106Places" add column if not exists "GoogleMapsUrl" text;
alter table public."TblP106Places" add column if not exists "OfficialUrl" text;
alter table public."TblP106Places" add column if not exists "SourceUrl" text;
alter table public."TblP106Places" add column if not exists "VisitStatus" text default '未去';
alter table public."TblP106Places" add column if not exists "DesireLevel" text default '待確認';
alter table public."TblP106Places" add column if not exists "MentionedByCompanionId" uuid;
alter table public."TblP106Places" add column if not exists "TimeTags" text[] default '{}';
alter table public."TblP106Places" add column if not exists "TriggerTags" text[] default '{}';
alter table public."TblP106Places" add column if not exists "MoodTags" text[] default '{}';
alter table public."TblP106Places" add column if not exists "BudgetLevel" text;
alter table public."TblP106Places" add column if not exists "ParkingNote" text;
alter table public."TblP106Places" add column if not exists "ReservationNote" text;
alter table public."TblP106Places" add column if not exists "PersonalNote" text;
alter table public."TblP106Places" add column if not exists "IsActive" boolean not null default true;
alter table public."TblP106Places" add column if not exists "CreatedAt" timestamptz not null default now();
alter table public."TblP106Places" add column if not exists "UpdatedAt" timestamptz not null default now();

-- Legacy NOT NULL columns must not block new V1.1 inserts that use CamelCase columns.
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='name') then
    alter table public."TblP106Places" alter column name drop not null;
  end if;
end $$;

-- Copy old lowercase place data into new columns, preserving old rows as hidden legacy rows until assigned to a user.
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='name') then
    update public."TblP106Places" set "PlaceName" = coalesce("PlaceName", name) where "PlaceName" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='area') then
    update public."TblP106Places" set "AreaText" = coalesce("AreaText", area) where "AreaText" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='route_tag') then
    update public."TblP106Places" set "RouteTag" = coalesce("RouteTag", route_tag) where "RouteTag" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='place_type') then
    update public."TblP106Places" set "PlaceType" = coalesce("PlaceType", place_type) where "PlaceType" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='address') then
    update public."TblP106Places" set "AddressText" = coalesce("AddressText", address) where "AddressText" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='google_maps_url') then
    update public."TblP106Places" set "GoogleMapsUrl" = coalesce("GoogleMapsUrl", google_maps_url) where "GoogleMapsUrl" is null;
  end if;
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Places' and column_name='official_url') then
    update public."TblP106Places" set "OfficialUrl" = coalesce("OfficialUrl", official_url) where "OfficialUrl" is null;
  end if;
end $$;

update public."TblP106Places" set "PlaceId" = gen_random_uuid() where "PlaceId" is null;
update public."TblP106Places" set "PlaceName" = coalesce("PlaceName", '(未命名地點)') where "PlaceName" is null;

-- Ensure PlaceId can be referenced even when older table primary key is still lowercase id.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'TblP106Places_PlaceId_key'
      and conrelid = 'public."TblP106Places"'::regclass
  ) then
    alter table public."TblP106Places" add constraint "TblP106Places_PlaceId_key" unique ("PlaceId");
  end if;
end $$;

-- Upgrade companion/source/candidate/note tables and relax legacy NOT NULL columns.
alter table public."TblP106Companions" add column if not exists "CompanionId" uuid default gen_random_uuid();
alter table public."TblP106Companions" add column if not exists "UserId" uuid references auth.users(id) on delete cascade default auth.uid();
alter table public."TblP106Companions" add column if not exists "CompanionName" text;
alter table public."TblP106Companions" add column if not exists "RelationLabel" text;
alter table public."TblP106Companions" add column if not exists "PreferenceTags" text[] default '{}';
alter table public."TblP106Companions" add column if not exists "AvoidanceTags" text[] default '{}';
alter table public."TblP106Companions" add column if not exists "Notes" text;
alter table public."TblP106Companions" add column if not exists "CreatedAt" timestamptz not null default now();
alter table public."TblP106Companions" add column if not exists "UpdatedAt" timestamptz not null default now();
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Companions' and column_name='name') then
    alter table public."TblP106Companions" alter column name drop not null;
  end if;
end $$;
update public."TblP106Companions" set "CompanionId" = gen_random_uuid() where "CompanionId" is null;
do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Companions' and column_name='name') then
    update public."TblP106Companions" set "CompanionName" = coalesce("CompanionName", name, '(未命名同行者)') where "CompanionName" is null;
  else
    update public."TblP106Companions" set "CompanionName" = coalesce("CompanionName", '(未命名同行者)') where "CompanionName" is null;
  end if;
end $$;

alter table public."TblP106Sources" add column if not exists "SourceId" uuid default gen_random_uuid();
alter table public."TblP106Sources" add column if not exists "UserId" uuid references auth.users(id) on delete cascade default auth.uid();
alter table public."TblP106Sources" add column if not exists "PlaceId" uuid;
alter table public."TblP106Sources" add column if not exists "SourceType" text default 'manual';
alter table public."TblP106Sources" add column if not exists "SourceUrl" text;
alter table public."TblP106Sources" add column if not exists "SourceTitle" text;
alter table public."TblP106Sources" add column if not exists "SourceNote" text;
alter table public."TblP106Sources" add column if not exists "CreatedAt" timestamptz not null default now();
alter table public."TblP106Sources" add column if not exists "UpdatedAt" timestamptz not null default now();
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106Sources' and column_name='place_id') then
    alter table public."TblP106Sources" alter column place_id drop not null;
  end if;
end $$;
update public."TblP106Sources" set "SourceId" = gen_random_uuid() where "SourceId" is null;

alter table public."TblP106TodayCandidates" add column if not exists "CandidateId" uuid default gen_random_uuid();
alter table public."TblP106TodayCandidates" add column if not exists "UserId" uuid references auth.users(id) on delete cascade default auth.uid();
alter table public."TblP106TodayCandidates" add column if not exists "PlaceId" uuid;
alter table public."TblP106TodayCandidates" add column if not exists "CandidateDate" date not null default current_date;
alter table public."TblP106TodayCandidates" add column if not exists "CandidateStatus" text default '候選';
alter table public."TblP106TodayCandidates" add column if not exists "Notes" text;
alter table public."TblP106TodayCandidates" add column if not exists "CreatedAt" timestamptz not null default now();
alter table public."TblP106TodayCandidates" add column if not exists "UpdatedAt" timestamptz not null default now();
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106TodayCandidates' and column_name='place_id') then
    alter table public."TblP106TodayCandidates" alter column place_id drop not null;
  end if;
end $$;
update public."TblP106TodayCandidates" set "CandidateId" = gen_random_uuid() where "CandidateId" is null;

alter table public."TblP106UserPlaceNotes" add column if not exists "NoteId" uuid default gen_random_uuid();
alter table public."TblP106UserPlaceNotes" add column if not exists "UserId" uuid references auth.users(id) on delete cascade default auth.uid();
alter table public."TblP106UserPlaceNotes" add column if not exists "PlaceId" uuid;
alter table public."TblP106UserPlaceNotes" add column if not exists "PersonalNote" text;
alter table public."TblP106UserPlaceNotes" add column if not exists "CreatedAt" timestamptz not null default now();
alter table public."TblP106UserPlaceNotes" add column if not exists "UpdatedAt" timestamptz not null default now();
do $$ begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='TblP106UserPlaceNotes' and column_name='place_id') then
    alter table public."TblP106UserPlaceNotes" alter column place_id drop not null;
  end if;
end $$;
update public."TblP106UserPlaceNotes" set "NoteId" = gen_random_uuid() where "NoteId" is null;

-- Clear old personal-feeling records as requested. Place rows are preserved.
truncate table public."TblP106UserPlaceNotes" restart identity cascade;
truncate table public."TblP106TodayCandidates" restart identity cascade;
truncate table public."TblP106Sources" restart identity cascade;
truncate table public."TblP106Companions" restart identity cascade;

-- 5. Trigger functions with fixed search_path.
create or replace function public."P106SetUpdatedAt"()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if to_jsonb(new) ? 'UpdatedAt' then
    new."UpdatedAt" = now();
  end if;
  return new;
end;
$$;

create or replace function public."P106EnsureUserId"()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if new."UserId" is null then
    new."UserId" := auth.uid();
  end if;
  return new;
end;
$$;

-- Drop both legacy and current P106 triggers, then recreate current triggers.
drop trigger if exists "TrgP106PlacesUpdatedAt" on public."TblP106Places";
drop trigger if exists "TrgP106NotesUpdatedAt" on public."TblP106UserPlaceNotes";
drop trigger if exists "TrgP106CompanionsUpdatedAt" on public."TblP106Companions";
drop trigger if exists "TrgP106CandidatesUpdatedAt" on public."TblP106TodayCandidates";

drop trigger if exists "P106SetUpdatedAt_TblP106Places" on public."TblP106Places";
create trigger "P106SetUpdatedAt_TblP106Places" before update on public."TblP106Places" for each row execute function public."P106SetUpdatedAt"();
drop trigger if exists "P106SetUpdatedAt_TblP106Companions" on public."TblP106Companions";
create trigger "P106SetUpdatedAt_TblP106Companions" before update on public."TblP106Companions" for each row execute function public."P106SetUpdatedAt"();
drop trigger if exists "P106SetUpdatedAt_TblP106Sources" on public."TblP106Sources";
create trigger "P106SetUpdatedAt_TblP106Sources" before update on public."TblP106Sources" for each row execute function public."P106SetUpdatedAt"();
drop trigger if exists "P106SetUpdatedAt_TblP106TodayCandidates" on public."TblP106TodayCandidates";
create trigger "P106SetUpdatedAt_TblP106TodayCandidates" before update on public."TblP106TodayCandidates" for each row execute function public."P106SetUpdatedAt"();
drop trigger if exists "P106SetUpdatedAt_TblP106UserPlaceNotes" on public."TblP106UserPlaceNotes";
create trigger "P106SetUpdatedAt_TblP106UserPlaceNotes" before update on public."TblP106UserPlaceNotes" for each row execute function public."P106SetUpdatedAt"();

drop trigger if exists "P106EnsureUserId_TblP106Places" on public."TblP106Places";
create trigger "P106EnsureUserId_TblP106Places" before insert on public."TblP106Places" for each row execute function public."P106EnsureUserId"();
drop trigger if exists "P106EnsureUserId_TblP106Companions" on public."TblP106Companions";
create trigger "P106EnsureUserId_TblP106Companions" before insert on public."TblP106Companions" for each row execute function public."P106EnsureUserId"();
drop trigger if exists "P106EnsureUserId_TblP106Sources" on public."TblP106Sources";
create trigger "P106EnsureUserId_TblP106Sources" before insert on public."TblP106Sources" for each row execute function public."P106EnsureUserId"();
drop trigger if exists "P106EnsureUserId_TblP106TodayCandidates" on public."TblP106TodayCandidates";
create trigger "P106EnsureUserId_TblP106TodayCandidates" before insert on public."TblP106TodayCandidates" for each row execute function public."P106EnsureUserId"();
drop trigger if exists "P106EnsureUserId_TblP106UserPlaceNotes" on public."TblP106UserPlaceNotes";
create trigger "P106EnsureUserId_TblP106UserPlaceNotes" before insert on public."TblP106UserPlaceNotes" for each row execute function public."P106EnsureUserId"();

-- 6. Indexes. These now run after migration-safe column additions.
create index if not exists "IdxP106PlacesUserUpdated" on public."TblP106Places" ("UserId", "UpdatedAt" desc);
create index if not exists "IdxP106PlacesUserArea" on public."TblP106Places" ("UserId", "AreaText");
create index if not exists "IdxP106PlacesUserStatus" on public."TblP106Places" ("UserId", "VisitStatus");
create index if not exists "IdxP106CompanionsUser" on public."TblP106Companions" ("UserId", "CreatedAt" desc);
create index if not exists "IdxP106CandidatesUserDate" on public."TblP106TodayCandidates" ("UserId", "CandidateDate" desc);
create index if not exists "IdxP106SourcesUser" on public."TblP106Sources" ("UserId", "CreatedAt" desc);

-- 7. Enable and force RLS.
alter table public."TblP106Places" enable row level security;
alter table public."TblP106Companions" enable row level security;
alter table public."TblP106Sources" enable row level security;
alter table public."TblP106TodayCandidates" enable row level security;
alter table public."TblP106UserPlaceNotes" enable row level security;

alter table public."TblP106Places" force row level security;
alter table public."TblP106Companions" force row level security;
alter table public."TblP106Sources" force row level security;
alter table public."TblP106TodayCandidates" force row level security;
alter table public."TblP106UserPlaceNotes" force row level security;

-- 8. Private authenticated policies. No anon policies are created.
create policy "P106 authenticated select own places" on public."TblP106Places" for select to authenticated using ("UserId" = auth.uid());
create policy "P106 authenticated insert own places" on public."TblP106Places" for insert to authenticated with check ("UserId" = auth.uid());
create policy "P106 authenticated update own places" on public."TblP106Places" for update to authenticated using ("UserId" = auth.uid()) with check ("UserId" = auth.uid());
create policy "P106 authenticated delete own places" on public."TblP106Places" for delete to authenticated using ("UserId" = auth.uid());

create policy "P106 authenticated select own companions" on public."TblP106Companions" for select to authenticated using ("UserId" = auth.uid());
create policy "P106 authenticated insert own companions" on public."TblP106Companions" for insert to authenticated with check ("UserId" = auth.uid());
create policy "P106 authenticated update own companions" on public."TblP106Companions" for update to authenticated using ("UserId" = auth.uid()) with check ("UserId" = auth.uid());
create policy "P106 authenticated delete own companions" on public."TblP106Companions" for delete to authenticated using ("UserId" = auth.uid());

create policy "P106 authenticated select own sources" on public."TblP106Sources" for select to authenticated using ("UserId" = auth.uid());
create policy "P106 authenticated insert own sources" on public."TblP106Sources" for insert to authenticated with check ("UserId" = auth.uid());
create policy "P106 authenticated update own sources" on public."TblP106Sources" for update to authenticated using ("UserId" = auth.uid()) with check ("UserId" = auth.uid());
create policy "P106 authenticated delete own sources" on public."TblP106Sources" for delete to authenticated using ("UserId" = auth.uid());

create policy "P106 authenticated select own candidates" on public."TblP106TodayCandidates" for select to authenticated using ("UserId" = auth.uid());
create policy "P106 authenticated insert own candidates" on public."TblP106TodayCandidates" for insert to authenticated with check ("UserId" = auth.uid());
create policy "P106 authenticated update own candidates" on public."TblP106TodayCandidates" for update to authenticated using ("UserId" = auth.uid()) with check ("UserId" = auth.uid());
create policy "P106 authenticated delete own candidates" on public."TblP106TodayCandidates" for delete to authenticated using ("UserId" = auth.uid());

create policy "P106 authenticated select own notes" on public."TblP106UserPlaceNotes" for select to authenticated using ("UserId" = auth.uid());
create policy "P106 authenticated insert own notes" on public."TblP106UserPlaceNotes" for insert to authenticated with check ("UserId" = auth.uid());
create policy "P106 authenticated update own notes" on public."TblP106UserPlaceNotes" for update to authenticated using ("UserId" = auth.uid()) with check ("UserId" = auth.uid());
create policy "P106 authenticated delete own notes" on public."TblP106UserPlaceNotes" for delete to authenticated using ("UserId" = auth.uid());

-- 9. Grants. Authenticated users rely on RLS; anon receives no table access.
revoke all on table public."TblP106Places" from anon;
revoke all on table public."TblP106Companions" from anon;
revoke all on table public."TblP106Sources" from anon;
revoke all on table public."TblP106TodayCandidates" from anon;
revoke all on table public."TblP106UserPlaceNotes" from anon;

grant select, insert, update, delete on table public."TblP106Places" to authenticated;
grant select, insert, update, delete on table public."TblP106Companions" to authenticated;
grant select, insert, update, delete on table public."TblP106Sources" to authenticated;
grant select, insert, update, delete on table public."TblP106TodayCandidates" to authenticated;
grant select, insert, update, delete on table public."TblP106UserPlaceNotes" to authenticated;

-- 10. Function execute permissions. No anon execution.
revoke all on function public."P106SetUpdatedAt"() from anon;
revoke all on function public."P106EnsureUserId"() from anon;
grant execute on function public."P106SetUpdatedAt"() to authenticated;
grant execute on function public."P106EnsureUserId"() to authenticated;

-- Optional manual step for legacy place rows:
-- Existing anonymous rows in TblP106Places are preserved but hidden because UserId is null.
-- To assign old rows to your account, replace the UUID below with your auth.users.id and run:
-- update public."TblP106Places" set "UserId" = '00000000-0000-0000-0000-000000000000' where "UserId" is null;
