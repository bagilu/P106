-- P106 現在要去哪裡｜Supabase SQL Schema
-- 請於 Supabase Dashboard > SQL Editor 貼上並執行。
-- 命名規則：資料表以 TblP106 開頭，資料庫函式以 P106 開頭。

create extension if not exists pgcrypto;

create table if not exists public."TblP106Places" (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  area text,
  route_tag text,
  place_type text default '其他',
  address text,
  google_maps_url text,
  official_url text,
  status_public text default '待確認',
  created_by text default 'anonymous',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."TblP106UserPlaceNotes" (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public."TblP106Places"(id) on delete cascade,
  owner_name text default '我',
  mentioned_by text,
  personal_status text default '未去',
  desire_level text default '想去',
  intent_note text,
  trigger_note text,
  context_tags text[] default '{}',
  mood_tags text[] default '{}',
  time_tags text[] default '{}',
  constraints_note text,
  budget_level text,
  parking_note text,
  reservation_note text,
  rating numeric(3,1),
  revisit boolean default false,
  remind_nearby boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."TblP106Sources" (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public."TblP106Places"(id) on delete cascade,
  source_type text default '手動',
  source_url text,
  source_text text,
  ai_summary text,
  ai_suggested_json jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public."TblP106Companions" (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  relation text,
  preference_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public."TblP106TodayCandidates" (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public."TblP106Places"(id) on delete cascade,
  session_title text default '今天候選',
  priority_level text default '候選',
  final_selected boolean default false,
  result_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists "IdxP106PlacesName" on public."TblP106Places" using gin (to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(area,'') || ' ' || coalesce(route_tag,'')));
create index if not exists "IdxP106NotesPlace" on public."TblP106UserPlaceNotes"(place_id);
create index if not exists "IdxP106NotesContextTags" on public."TblP106UserPlaceNotes" using gin(context_tags);
create index if not exists "IdxP106NotesTimeTags" on public."TblP106UserPlaceNotes" using gin(time_tags);

create or replace function public."P106SetUpdatedAt"()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists "TrgP106PlacesUpdatedAt" on public."TblP106Places";
create trigger "TrgP106PlacesUpdatedAt"
before update on public."TblP106Places"
for each row execute function public."P106SetUpdatedAt"();

drop trigger if exists "TrgP106NotesUpdatedAt" on public."TblP106UserPlaceNotes";
create trigger "TrgP106NotesUpdatedAt"
before update on public."TblP106UserPlaceNotes"
for each row execute function public."P106SetUpdatedAt"();

drop trigger if exists "TrgP106CompanionsUpdatedAt" on public."TblP106Companions";
create trigger "TrgP106CompanionsUpdatedAt"
before update on public."TblP106Companions"
for each row execute function public."P106SetUpdatedAt"();

drop trigger if exists "TrgP106CandidatesUpdatedAt" on public."TblP106TodayCandidates";
create trigger "TrgP106CandidatesUpdatedAt"
before update on public."TblP106TodayCandidates"
for each row execute function public."P106SetUpdatedAt"();

-- P106AddPlace：可供未來 RPC 使用。前端目前以 Supabase JS 直接 upsert 主要資料表。
create or replace function public."P106AddPlace"(
  p_name text,
  p_area text default null,
  p_route_tag text default null,
  p_place_type text default '其他',
  p_address text default null,
  p_google_maps_url text default null,
  p_official_url text default null
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_id uuid;
begin
  insert into public."TblP106Places"(name, area, route_tag, place_type, address, google_maps_url, official_url)
  values (p_name, p_area, p_route_tag, p_place_type, p_address, p_google_maps_url, p_official_url)
  returning id into v_id;
  return v_id;
end;
$$;

-- P106SearchPlaces：情境喚回查詢基礎版。
create or replace function public."P106SearchPlaces"(
  p_keyword text default '',
  p_area text default '',
  p_status text default ''
)
returns table(
  place_id uuid,
  name text,
  area text,
  place_type text,
  personal_status text,
  mentioned_by text,
  trigger_note text,
  intent_note text,
  created_at timestamptz
)
language sql
stable
as $$
  select
    p.id, p.name, p.area, p.place_type,
    n.personal_status, n.mentioned_by, n.trigger_note, n.intent_note, p.created_at
  from public."TblP106Places" p
  left join public."TblP106UserPlaceNotes" n on n.place_id = p.id
  where
    (coalesce(p_keyword,'') = '' or
      p.name ilike '%' || p_keyword || '%' or
      coalesce(p.area,'') ilike '%' || p_keyword || '%' or
      coalesce(n.intent_note,'') ilike '%' || p_keyword || '%' or
      coalesce(n.trigger_note,'') ilike '%' || p_keyword || '%')
    and (coalesce(p_area,'') = '' or coalesce(p.area,'') ilike '%' || p_area || '%')
    and (coalesce(p_status,'') = '' or coalesce(n.personal_status,'') = p_status)
  order by p.created_at desc;
$$;

alter table public."TblP106Places" enable row level security;
alter table public."TblP106UserPlaceNotes" enable row level security;
alter table public."TblP106Sources" enable row level security;
alter table public."TblP106Companions" enable row level security;
alter table public."TblP106TodayCandidates" enable row level security;

-- 教學展示版：允許 anon 讀寫。若日後要做正式多人帳號，請改成 auth.uid() 權限控管。
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Places' and policyname='P106 anon select places') then
    create policy "P106 anon select places" on public."TblP106Places" for select to anon using (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Places' and policyname='P106 anon insert places') then
    create policy "P106 anon insert places" on public."TblP106Places" for insert to anon with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Places' and policyname='P106 anon update places') then
    create policy "P106 anon update places" on public."TblP106Places" for update to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Places' and policyname='P106 anon delete places') then
    create policy "P106 anon delete places" on public."TblP106Places" for delete to anon using (true);
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106UserPlaceNotes' and policyname='P106 anon all notes') then
    create policy "P106 anon all notes" on public."TblP106UserPlaceNotes" for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Sources' and policyname='P106 anon all sources') then
    create policy "P106 anon all sources" on public."TblP106Sources" for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106Companions' and policyname='P106 anon all companions') then
    create policy "P106 anon all companions" on public."TblP106Companions" for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='TblP106TodayCandidates' and policyname='P106 anon all candidates') then
    create policy "P106 anon all candidates" on public."TblP106TodayCandidates" for all to anon using (true) with check (true);
  end if;
end $$;
