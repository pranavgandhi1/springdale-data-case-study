-- Reconciliation: every non-null severity_raw in staging must produce a non-null severity_label in fct.
-- Returns the count of orphaned raw values. Empty result = pass.

select distinct
    s.severity_raw
from {{ ref('stg_tickets') }} s
left join {{ ref('seed_enum_canonical_severity') }} m
    on s.severity_raw = m.raw_value
where s.severity_raw is not null
  and m.severity_label is null
