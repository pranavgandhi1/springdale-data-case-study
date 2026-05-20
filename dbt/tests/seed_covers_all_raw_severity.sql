-- Hard fail: any raw severity value in source that the seed does not map.
-- Empty result = all raw values have a canonical mapping.

with raw_severities as (
    select distinct severity_raw
    from {{ ref('stg_tickets') }}
    where severity_raw is not null
),

mapped as (
    select distinct raw_value
    from {{ ref('seed_enum_canonical_severity') }}
)

select rs.severity_raw
from raw_severities rs
left join mapped m on rs.severity_raw = m.raw_value
where m.raw_value is null
