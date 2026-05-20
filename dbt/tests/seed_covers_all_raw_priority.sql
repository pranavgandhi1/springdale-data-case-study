-- Hard fail: any raw priority value in source that the seed does not map.

with raw_priorities as (
    select distinct priority_raw
    from {{ ref('stg_tickets') }}
    where priority_raw is not null
),

mapped as (
    select distinct raw_value
    from {{ ref('seed_enum_canonical_priority') }}
)

select rp.priority_raw
from raw_priorities rp
left join mapped m on rp.priority_raw = m.raw_value
where m.raw_value is null
