with source as (
    select * from {{ source('it_source', 'it_tickets') }}
),

renamed as (
    select
        id_ticket                                 as ticket_id,
        split_part(id_ticket, '-', 1)             as ticket_prefix,

        try_to_date(date, 'MM/DD/YYYY')           as created_date,

        employee_id                               as employee_id,
        agent_id                                  as agent_id,

        trim(request_category)                    as request_category,
        trim(issue_type)                          as issue_type,

        trim(severity)                            as severity_raw,
        trim(priority)                            as priority_raw,

        resolution_time_days_::integer            as resolution_time_days,
        satisfaction_rate::integer                as satisfaction_rating,

        _airbyte_raw_id,
        _airbyte_extracted_at
    from source
),

severity_canonical as (
    select
        renamed.*,
        sev.severity_level,
        sev.severity_label
    from renamed
    left join {{ ref('seed_enum_canonical_severity') }} sev
        on renamed.severity_raw = sev.raw_value
),

final as (
    select
        sc.*,
        pri.priority_level,
        pri.priority_label
    from severity_canonical sc
    left join {{ ref('seed_enum_canonical_priority') }} pri
        on sc.priority_raw = pri.raw_value
)

select * from final
