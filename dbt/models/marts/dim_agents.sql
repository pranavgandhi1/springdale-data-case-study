select
    agent_id,
    full_name  as agent_name,
    email      as agent_email,
    birth_date as agent_birth_date,
    age_years  as agent_age_years
from {{ ref('stg_agents') }}
