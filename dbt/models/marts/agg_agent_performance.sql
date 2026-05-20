select
    f.agent_id,
    a.agent_name,
    count(*) as tickets_handled,
    round(avg(f.resolution_time_days), 2) as avg_resolution_days,
    round(avg(f.satisfaction_rating), 2)  as avg_csat,
    round(100.0 * sum(case when f.is_sla_breach then 1 else 0 end) / count(*), 2) as sla_breach_rate_pct,
    sum(case when f.satisfaction_rating is not null then 1 else 0 end) as csat_response_count,
    round(100.0 * sum(case when f.satisfaction_rating is not null then 1 else 0 end) / count(*), 2) as csat_response_rate_pct
from {{ ref('fct_tickets') }} f
left join {{ ref('dim_agents') }} a using (agent_id)
where f.agent_id is not null
group by 1, 2
order by tickets_handled desc
