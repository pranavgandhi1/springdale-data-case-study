-- Reconciliation: sum of tickets_total in agg_demand_mix must equal fct_tickets count.

with demand_sum as (
    select sum(tickets_total) as n from {{ ref('agg_demand_mix') }}
),
fct_count as (
    select count(*) as n from {{ ref('fct_tickets') }}
)

select
    'demand_total' as check_name,
    d.n as demand_sum,
    f.n as fct_count
from demand_sum d, fct_count f
where d.n != f.n
