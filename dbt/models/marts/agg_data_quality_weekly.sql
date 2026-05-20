select
    created_week as week_date,
    count(*) as tickets_total,
    round(100.0 * sum(case when is_severity_unclassified then 1 else 0 end) / count(*), 2) as pct_severity_unclassified,
    round(100.0 * sum(case when is_priority_unassigned then 1 else 0 end) / count(*), 2) as pct_priority_unassigned,
    round(100.0 * sum(case when is_csat_missing then 1 else 0 end) / count(*), 2) as pct_csat_missing,
    sum(case when is_severity_priority_misaligned then 1 else 0 end) as count_severity_priority_misaligned,
    sum(case when is_zero_resolution_time then 1 else 0 end) as count_zero_resolution_time
from {{ ref('fct_tickets') }}
group by 1
order by 1
