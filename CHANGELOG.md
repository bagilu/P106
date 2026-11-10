# P106 NowWhere Changelog

## V2.300 — SBI-P-SDS v3.7 staged migration — 2026-11-10
- Added Web Version V2.300 and cache busting.
- Updated visible SDS label to SBI-P-SDS v3.7.
- Standardized homepage footer institution → Web Version → SDS order.
- Confirmed institutional 好玩實驗室 link points to P101.
- Added P101 centralized analytics loader with data-project=P106.
- Added analytics/privacy notice.
- Added P101 central analytics registration and verification SQL.
- Added P106 v3.7 RPC-only migration.
- Added ready-to-activate RPC-only frontend at js/app.rpc-v37.js.
- Updated Permissions and HealthCheck SQL for direct-table-access revocation and RPC least privilege.
- Production app.js intentionally remains active until the RPC migration is executed, preventing a live outage.


## V2.1 Parking & Station Ranges Candidate — 2026-09-05
- Fixed PostgreSQL 42P13 when changing `P106SearchPublicPlaces()` RETURNS TABLE signature by dropping the old P106 function before recreation.
- Parking changed from boolean to multi-select: 方便／普通／不方便.
- Station distance changed from boolean to multi-select: 近／普通／遠.
- Added `ParkingLevels text[]` and `StationDistanceLevels text[]`.
- Existing V2.0 boolean values are best-effort migrated to the new arrays.
- Public-share RPC now returns the new range fields and still hides private columns.
- Old boolean columns remain for compatibility but are no longer used by the V2.1 frontend.


## V2.1 Parking & Station Ranges Candidate — 2026-09-05
- Fixed PostgreSQL 42P13 when changing `P106SearchPublicPlaces()` RETURNS TABLE signature by dropping the old P106 function before recreation.
- Redesigned place capture around retrieval-oriented fields.
- Added multi-select 食／住／景 categories.
- Added 8 budget ranges.
- Added country + second-level region selection.
- Added atmosphere, transportation, party-size, and time-slot fields.
- Added optional private note.
- Added `IsPublic`, default false.
- Split retrieval into「我的地點」and「公開地點」.
- Added authenticated-only `P106SearchPublicPlaces()` safe projection.
- Public search does not expose `UserId` or `PersonalNote`.
- Added `emailRedirectTo` to signup.
- Added project-specific Auth `storageKey = p106-auth-token`.
- Preserved Japanese-literary × Taiwan-public-service visual direction.
- AI remains disabled.
- Migration is additive and preserves existing V1.1.1 rows and legacy columns.

## V1.1.1 Auth Personal SQL Migration Fix
- Fixed legacy column migration issues.
- Preserved old place rows.
- Email + Password Auth personal edition.