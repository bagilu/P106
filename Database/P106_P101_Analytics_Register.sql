-- P101 Central Analytics: register P106
-- CONTROLLED EXCEPTION: run only by an authorized P101 platform administrator
-- in the central Supabase SQL Editor. Do NOT mix this into P106 automatic migration.

insert into p101_analytics."TblP101AnalyticsProjects"
    (project_code, canonical_origin, enabled)
values
    ('P106', 'https://bagilu.github.io', true)
on conflict (project_code)
do update set
    canonical_origin = excluded.canonical_origin,
    enabled = excluded.enabled;
