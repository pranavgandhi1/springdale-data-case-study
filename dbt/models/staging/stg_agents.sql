with source as (
    select * from {{ source('it_source', 'it_agents') }}
),

renamed as (
    select
        agent_id              as agent_id,
        trim(full_name)       as full_name,
        trim(email)           as email,
        year_of_birth::integer  as birth_year,
        month_of_birth::integer as birth_month,
        day_of_birth::integer   as birth_day,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
),

with_dates as (
    select
        agent_id,
        full_name,
        email,
        try_to_date(
            birth_year::varchar || '-' ||
            lpad(birth_month::varchar, 2, '0') || '-' ||
            lpad(birth_day::varchar, 2, '0'),
            'YYYY-MM-DD'
        ) as birth_date,
        _airbyte_raw_id,
        _airbyte_extracted_at
    from renamed
)

select
    agent_id,
    full_name,
    email,
    birth_date,
    datediff('year', birth_date, current_date) as age_years,
    _airbyte_raw_id,
    _airbyte_extracted_at
from with_dates
