select
    severity_level,
    severity_label,
    priority_level,
    priority_label,
    count(*) as ticket_count,
    round(100.0 * count(*) / sum(count(*)) over (), 2) as pct_of_total
from {{ ref('fct_tickets') }}
group by 1, 2, 3, 4
order by severity_level desc, priority_level desc
