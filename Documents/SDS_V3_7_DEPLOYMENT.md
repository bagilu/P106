# P106 V2.300 / SBI-P-SDS v3.7 Deployment

## Phase A — already safe to deploy on GitHub Pages
The following are non-breaking and may be deployed before the database migration:
- footer identification + Web Version + SDS v3.7;
- P101 link on 好玩實驗室;
- cache busting;
- P101 analytics loader;
- privacy/analytics notice;
- migration and governance SQL files.

## Phase B — RPC-only database transition
Run:
`Database/Migrations/P106_V2_300_SDS37_RPC_Only.sql`

This migration:
- keeps existing P106 data;
- keeps RLS enabled/forced;
- creates P106-specific RPCs;
- revokes direct table access from `anon` and `authenticated`;
- grants only necessary authenticated RPC EXECUTE;
- keeps public search least-data;
- uses SECURITY DEFINER only for the reviewed RPC boundary with fixed empty search_path and explicit auth.uid() checks.

## Phase C — activate RPC-only frontend
Only after Phase B succeeds:
1. replace production `js/app.js` with `js/app.rpc-v37.js`;
2. keep `index.html` loading `js/app.js?v=2.300`;
3. deploy;
4. run `Database/99_P106_HealthCheck.sql`.

## Required functional tests
### Account A
- login succeeds;
- list own places succeeds;
- create/update/delete own place succeeds;
- private place remains private;
- public place may be discovered by another authenticated user.

### Account B
- cannot read A private place;
- cannot update/delete A place;
- can discover A public place through P106SearchPublicPlaces;
- does not receive A UserId or PersonalNote.

### Direct Data API
After RPC migration:
- direct authenticated table SELECT must fail;
- direct INSERT/UPDATE/DELETE must fail;
- anon table access must fail.

## P101 analytics
Execute separately as P101 platform administrator:
- `Database/P106_P101_Analytics_Register.sql`

Then verify:
- `Database/P106_P101_Analytics_Verify.sql`

Expected:
- project_code = P106
- canonical_origin = https://bagilu.github.io
- enabled = true

Then visit the P106 homepage and confirm the P101 analytics dashboard receives events.

## Notes
P101 registration is a controlled cross-project governance exception. Do not merge it into P106 migration.
