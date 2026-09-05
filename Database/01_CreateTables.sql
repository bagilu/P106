-- P106 V2 fresh install: tables only.
-- Scope: P106 only.
create extension if not exists pgcrypto;

create table if not exists public."TblP106Places" (
  "PlaceId" uuid primary key default gen_random_uuid(),
  "UserId" uuid not null references auth.users(id) on delete cascade default auth.uid(),
  "PlaceName" text not null,
  "Categories" text[] not null default '{}',
  "BudgetRanges" text[] not null default '{}',
  "CountryCode" text not null default 'TW',
  "RegionText" text,
  "Atmospheres" text[] not null default '{}',
  "ParkingConvenient" boolean,
  "NearStation" boolean,
  "ParkingLevels" text[] not null default '{}',
  "StationDistanceLevels" text[] not null default '{}',
  "PartySizes" text[] not null default '{}',
  "TimeSlotsV2" text[] not null default '{}',
  "PersonalNote" text,
  "GoogleMapsUrl" text,
  "IsPublic" boolean not null default false,
  "IsActive" boolean not null default true,
  "CreatedAt" timestamptz not null default now(),
  "UpdatedAt" timestamptz not null default now()
);
