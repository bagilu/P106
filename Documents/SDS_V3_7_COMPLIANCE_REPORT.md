# P106 SDS v3.7 Compliance Report

Project: P106
Web Version: V2.300
SDS: SBI-P-SDS v3.7
Date: 2026-11-10

| QA | Status | Result |
|---|---|---|
| QA-01 RLS Always On | REVIEW | Existing P106 table SQL enables/forces RLS; live catalog check required. |
| QA-02 No direct Table/View CRUD | PASS | Production app.js now uses P106 RPCs only; no direct table CRUD remains. |
| QA-03 RPC Only | PASS | P106 RPC-only migration executed successfully and production frontend activated. |
| QA-04 Exposed Schemas | REVIEW | Must be checked in Supabase Dashboard / Data API settings. |
| QA-05 Least table grants | REVIEW | Migration executed; catalog verification via 99_P106_HealthCheck.sql still required. |
| QA-06 RLS policies | REVIEW | A/B allow/deny testing required after migration. |
| QA-07 Least Data | PASS | My-list and public-list RPCs return explicit fields; public RPC omits UserId and PersonalNote. |
| QA-08 PUBLIC EXECUTE | PASS in migration | Migration revokes PUBLIC/anon execution and grants authenticated only. |
| QA-09 DEFINER safety | REVIEW | Functions use fixed empty search_path, schema-qualified tables, explicit auth.uid checks; live tests required. |
| QA-10 secrets | PASS | No service-role key added. |
| QA-11 password show/hide | PASS | Existing login UI has keyboard-operable show/hide control. |
| QA-12 config/secrets | REVIEW | config-sample exists; historical committed config.js should be assessed separately. |
| QA-13 project scope | PASS | New SQL only changes P106 objects, except separately labeled P101 governance registration SQL. |
| QA-15 Web Version/cache busting | PASS | V2.300 applied to CSS/JS. |
| QA-16 footer order/version | PASS | Institution → Web Version → SDS v3.7. |
| QA-24 P101 lab link | PASS | Homepage institutional 好玩實驗室 links to P101. |
| QA-25 P101 analytics loader | PASS | Single homepage analytics loader uses data-project=P106. |
| QA-26 analytics E2E | REVIEW | Must verify in P101 admin dashboard. |
| QA-27 analytics platform protections | N/A | P101 platform governance responsibility. |
| QA-28 P101 registration SQL | PASS | Registration SQL executed successfully; read-only verification remains available in repository. |

No FAIL is intentionally marked PASS. Items requiring live Supabase or P101 administrative verification remain REVIEW.
