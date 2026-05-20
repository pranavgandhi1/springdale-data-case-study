-- Reconciliation: raw agent count must equal dim_agents count.

with raw_count as (
    select count(*) as n from {{ source('it_source', 'it_agents') }}
),
dim_count as (
    select count(*) as n from {{ ref('dim_agents') }}
)

select
    'agent_row_count' as check_name,
    r.n as raw_n,
    d.n as dim_n
from raw_count r, dim_count d
where r.n != d.n
