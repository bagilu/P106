-- P101 Central Analytics: verify P106 registration (read-only)
select project_code, canonical_origin, enabled
from p101_analytics."TblP101AnalyticsProjects"
where project_code = 'P106';
