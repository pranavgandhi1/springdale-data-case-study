-- Reconciliation: raw ticket row count must equal fct_tickets row count.
-- Empty result = pass.

with raw_count as (
    select count(*) as n from {{ source('it_source', 'it_tickets') }}
),
fct_count as (
    select count(*) as n from {{ ref('fct_tickets') }}
)

select
    'ticket_row_count' as check_name,
    r.n as raw_n,
    f.n as fct_n
from raw_count r, fct_count f
where r.n != f.n
