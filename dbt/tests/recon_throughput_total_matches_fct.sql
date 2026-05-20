-- Reconciliation: sum of tickets_created in agg_throughput_daily must equal fct_tickets count.

with throughput_sum as (
    select sum(tickets_created) as n from {{ ref('agg_throughput_daily') }}
),
fct_count as (
    select count(*) as n from {{ ref('fct_tickets') }}
)

select
    'throughput_total' as check_name,
    t.n as throughput_sum,
    f.n as fct_count
from throughput_sum t, fct_count f
where t.n != f.n
