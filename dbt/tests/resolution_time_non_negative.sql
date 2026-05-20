-- Hard fail: resolution_time_days must be non-negative.
-- Empty result = test passes.

select
    ticket_id,
    resolution_time_days
from {{ ref('fct_tickets') }}
where resolution_time_days < 0
