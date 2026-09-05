# README_AI — P106 V2

- Project: P106「現在要去哪裡」
- Baseline entering V2: V1.1.1 Auth Personal SQLFIX
- Current package: V2.1 Parking & Station Ranges Candidate
- Frontend: GitHub Pages
- Backend: Supabase Auth + PostgreSQL
- Auth storageKey: `p106-auth-token`
- AI features: disabled

## Hard constraints
1. Follow P-SDS.
2. SQL may touch only `TblP106...`, `P106...`, `ViewP106...`, and explicitly P106-named objects.
3. Never use schema-wide GRANT/REVOKE/ALTER DEFAULT PRIVILEGES.
4. Do not include production `config.js` in release ZIP.
5. Do not expose `service_role`.
6. Public sharing must not expose `UserId` or `PersonalNote`.
7. Public discovery is authenticated-only in V2.
8. Do not restore old anonymous P106 access.
9. Do not re-enable AI unless explicitly requested.
10. Existing V1.1.1 deployment uses only `Database/Migrations/P106_V2_0_Migration.sql`.

## V2 query model
Hard filter:
- Categories
- name keyword
- BudgetRanges
- CountryCode
- RegionText

Preference ranking:
- Atmospheres
- ParkingConvenient
- NearStation
- PartySizes
- TimeSlotsV2
