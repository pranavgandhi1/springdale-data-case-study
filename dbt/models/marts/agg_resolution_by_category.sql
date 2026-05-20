select
    request_category,
    count(*) as ticket_count,
    percentile_cont(0.50) within group (order by resolution_time_days) as median_resolution_days,
    round(avg(resolution_time_days), 2) as avg_resolution_days,
    percentile_cont(0.90) within group (order by resolution_time_days) as p90_resolution_days,
    round(100.0 * sum(case when is_sla_breach then 1 else 0 end) / count(*), 2) as sla_breach_pct
from {{ ref('fct_tickets') }}
group by 1
order by median_resolution_days desc
