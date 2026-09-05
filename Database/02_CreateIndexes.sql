-- P106 V2 indexes only.
create index if not exists "IdxP106PlacesUserUpdatedV2" on public."TblP106Places" ("UserId","UpdatedAt" desc);
create index if not exists "IdxP106PlacesPublicUpdatedV2" on public."TblP106Places" ("IsPublic","UpdatedAt" desc) where "IsPublic" = true;
create index if not exists "IdxP106PlacesCategoriesV2" on public."TblP106Places" using gin ("Categories");
create index if not exists "IdxP106PlacesBudgetsV2" on public."TblP106Places" using gin ("BudgetRanges");
create index if not exists "IdxP106PlacesAtmospheresV2" on public."TblP106Places" using gin ("Atmospheres");

create index if not exists "IdxP106PlacesParkingLevelsV21" on public."TblP106Places" using gin ("ParkingLevels");
create index if not exists "IdxP106PlacesStationDistanceV21" on public."TblP106Places" using gin ("StationDistanceLevels");
