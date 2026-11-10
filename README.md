# P106 現在要去哪裡｜NowWhere

## Current Web Version
- Web Version: **V2.300**
- SDS target: **SBI-P-SDS v3.7**
- Frontend: GitHub Pages
- Backend: shared Supabase Auth + PostgreSQL
- Account lifecycle: P130 Account Center
- AI: disabled

## Project purpose
P106 is a context-based personal place retrieval system. Users record places they want to remember and later retrieve them by category, budget, location, atmosphere, parking, station distance, party size, and time slot.

## V2 core fields
- 食／住／景：可複選
- 名稱：文字
- 大致預算：8 個級距
- 國家＋第二層行政區
- 氣氛
- 停車：方便／普通／不方便
- 距離車站：近／普通／遠
- 適合人數
- 適合時段
- 私人備註
- 是否公開

## Auth
P106 retains its own Email + Password sign-in page and uses shared Supabase Auth.
Registration, Email verification, forgot/reset/change password, account profile, and cross-project account administration are handled by P130.

Project auth storageKey:
`P106-auth`

## SBI-P-SDS v3.7 upgrade
V2.300 introduces:
1. Footer identification in required order:
   `慈濟大學｜經營管理學系｜好玩實驗室 · Web Version V2.300 · SBI-P-SDS v3.7`
2. Every institutional “好玩實驗室” link points to:
   `https://tcubmdsbilab.github.io/P101/`
3. CSS/JS cache busting uses V2.300.
4. P101 centralized anonymous analytics is loaded once on `index.html` with `data-project="P106"`.
5. P101 central registration SQL and read-only verification SQL are included.
6. RPC-only migration and RPC-only frontend are prepared.

## Important deployment state
The production page has received all **non-breaking frontend v3.7 changes**.

The RPC-only database transition is intentionally staged:
- Migration: `Database/Migrations/P106_V2_300_SDS37_RPC_Only.sql`
- Ready frontend: `js/app.rpc-v37.js`

The current active `js/app.js` must not be replaced by `app.rpc-v37.js` until the Supabase migration has been executed successfully. This sequencing prevents a production outage.

After the migration succeeds:
1. replace active `js/app.js` with the contents of `js/app.rpc-v37.js`;
2. run `Database/99_P106_HealthCheck.sql`;
3. verify direct table grants are absent;
4. perform A/B account allow/deny tests.

## P101 centralized analytics
The public homepage loads:
`https://tcubmdsbilab.github.io/P101/analytics/v0.1/analytics.js`

Project Code:
`P106`

Central registration files:
- `Database/P106_P101_Analytics_Register.sql`
- `Database/P106_P101_Analytics_Verify.sql`

The registration SQL is a controlled P101 platform governance operation. It must be executed by an authorized P101 administrator and is not part of the P106 automatic migration.

## Security
- RLS remains required.
- No service-role key is placed in public frontend code.
- Production `config.js` contains only public Supabase connection settings.
- Release templates use `config-sample.js`.
- P106 database changes are project-scoped.
- Public place search does not return `UserId` or `PersonalNote`.

## Footer
The homepage footer contains the institutional identification, Web Version and SDS version. “好玩實驗室” links back to P101.
