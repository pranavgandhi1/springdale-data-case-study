select
    request_category,
    issue_type,
    ticket_prefix,
    count(*) as tickets_total,
    round(avg(resolution_time_days), 2) as avg_resolution_days,
    round(avg(satisfaction_rating), 2)  as avg_csat
from {{ ref('fct_tickets') }}
group by 1, 2, 3
order by tickets_total desc
