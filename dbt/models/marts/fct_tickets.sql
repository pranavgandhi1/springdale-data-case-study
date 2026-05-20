select
    ticket_id,
    ticket_prefix,
    employee_id,
    agent_id,
    agent_name,
    agent_email,

    created_date,
    closed_date,
    created_dow,
    created_week,
    created_month,

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

    is_sla_breach,

    is_severity_unclassified,
    is_priority_unassigned,
    is_csat_missing,
    is_severity_priority_misaligned,
    is_zero_resolution_time

from {{ ref('int_ticket_with_agent') }}
