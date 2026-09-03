# P106 NowWhere Changelog

## V1.1.1 Auth Personal SQL Migration Fix

- Fixed SQL error: `column "AreaText" does not exist`.
- Made the schema migration safe for databases that already ran P106 V1.0/V1.0.1.
- Added migration steps from legacy lowercase columns (`name`, `area`, `route_tag`, etc.) to V1.1 CamelCase columns (`PlaceName`, `AreaText`, `RouteTag`, etc.).
- Relaxed legacy NOT NULL columns so new V1.1 frontend inserts are not blocked by old V1.0 columns.
- Preserved old `TblP106Places` rows but kept them hidden until assigned to an authenticated `UserId`.
- Kept AI disabled in V1.1.x.
- Kept ZIP filename ASCII-safe.

## V1.1 Auth Personal

- Added Supabase Auth Email + Password login.
- Converted P106 to a personal place library.
- Removed anonymous open RLS policies.
- Disabled AI functions and removed OpenAI API key requirement.
