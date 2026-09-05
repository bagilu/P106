# P106 V2 Database

## Existing V1.1.1 deployment
Run only:

`Migrations/P106_V2_0_Migration.sql`

Do **not** rerun the fresh-install sequence over an existing deployment.

The migration is additive:
- preserves existing rows;
- preserves legacy V1.1 columns;
- adds V2 retrieval fields and `IsPublic`;
- replaces only `TblP106Places` policies;
- adds `P106SearchPublicPlaces()` for safe public sharing.

## Fresh deployment
Run in order:
1. `01_CreateTables.sql`
2. `02_CreateIndexes.sql`
3. `03_CreateViews.sql`
4. `04_CreateFunctions.sql`
5. `05_EnableRLS.sql`
6. `06_CreatePolicies.sql`
7. `07_GrantPermissions.sql`
8. `08_SeedData.sql` (no-op)

Repair/check:
- `90_P106_Permissions.sql`
- `99_P106_HealthCheck.sql`
