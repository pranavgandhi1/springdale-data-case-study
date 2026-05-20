select
    f.agent_id,
    a.agent_name,
    date_trunc('week', f.closed_date)::date as week_date,
    count(*) as tickets_resolved
from {{ ref('fct_tickets') }} f
left join {{ ref('dim_agents') }} a using (agent_id)
where f.closed_date is not null
  and f.agent_id is not null
group by 1, 2, 3
order by week_date desc, tickets_resolved desc
