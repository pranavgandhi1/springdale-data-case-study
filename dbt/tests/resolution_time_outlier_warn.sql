{{ config(severity = 'warn') }}

-- Warn if any ticket exceeds the configured outlier threshold (default 90 days).
-- Configurable via var: resolution_time_outlier_days.

select
    ticket_id,
    resolution_time_days
from {{ ref('fct_tickets') }}
where resolution_time_days > {{ var('resolution_time_outlier_days', 90) }}
