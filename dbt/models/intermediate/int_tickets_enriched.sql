with tickets as (
    select * from {{ ref('stg_tickets') }}
),

enriched as (
    select
        ticket_id,
        ticket_prefix,
        created_date,
        employee_id,
        agent_id,

        request_category,
        issue_type,

        severity_raw,
        severity_level,
        severity_label,
        priority_raw,
        priority_level,
        priority_label,

        resolution_time_days,
        satisfaction_rating,

        dateadd('day', resolution_time_days, created_date) as closed_date,

        case when resolution_time_days > {{ var('sla_threshold_days', 3) }} then true else false end as is_sla_breach,

        case when severity_level = 0 then true else false end as is_severity_unclassified,
        case when priority_level = 0 then true else false end as is_priority_unassigned,
        case when satisfaction_rating is null then true else false end as is_csat_missing,
        case
            when severity_level >= 3 and priority_level <= 1 then true
            else false
        end as is_severity_priority_misaligned,
        case when resolution_time_days = 0 then true else false end as is_zero_resolution_time,

        dayofweek(created_date)              as created_dow,
        date_trunc('week', created_date)     as created_week,
        date_trunc('month', created_date)    as created_month,

        _airbyte_raw_id,
        _airbyte_extracted_at
    from tickets
)

select * from enriched
