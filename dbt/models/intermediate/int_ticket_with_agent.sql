with tickets as (
    select * from {{ ref('int_tickets_enriched') }}
),

agents as (
    select
        agent_id,
        full_name  as agent_name,
        email      as agent_email,
        age_years  as agent_age_years
    from {{ ref('stg_agents') }}
)

select
    t.*,
    a.agent_name,
    a.agent_email,
    a.agent_age_years
from tickets t
left join agents a using (agent_id)
