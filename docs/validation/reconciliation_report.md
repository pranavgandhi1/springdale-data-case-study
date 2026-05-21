# Reconciliation Report

Compares raw Airbyte-loaded tables in `SPRINGDALE_RAW.IT_SOURCE` against the transformed marts in `SPRINGDALE_ANALYTICS.MARTS`. Each check is either a row-count equality, an aggregate match, or a value-level spot check.

## Summary

| Check | Raw | Transformed | Result |
|---|---|---|---|
| Ticket row count: raw vs fct_tickets | 97,498 | 97,498 | PASS |
| Agent row count: raw vs dim_agents | 50 | 50 | PASS |
| Throughput tickets_created sum vs fct_tickets count | 97,498 | 97,498 | PASS |
| Demand mix tickets_total sum vs fct_tickets count | 97,498 | 97,498 | PASS |
| Severity raw values with no canonical mapping | 0 expected | 0 | PASS |
| Priority raw values with no canonical mapping | 0 expected | 0 | PASS |
| Spot-check 10 random tickets (severity mapping + resolution_time preserved) | 10 sampled | 10 verified | PASS |

## Spot-check detail

- `GMREST-2043388823`: severity `3 - Mayor` → expected `Major`, actual `Major` (OK); resolution_time `10` → `10` (OK)
- `SDLTET-0444105870`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `4` → `4` (OK)
- `KWLTNR-5043374320`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `0` → `0` (OK)
- `TDLESR-9344126173`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `3` → `3` (OK)
- `GHLTSR-5643140453`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `6` → `6` (OK)
- `GHLTSR-0643923598`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `6` → `6` (OK)
- `KDLTET-5542605561`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `5` → `5` (OK)
- `TMLTSR-0744030566`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `7` → `7` (OK)
- `GDRTSR-6644009258`: severity `3 - Mayor` → expected `Major`, actual `Major` (OK); resolution_time `6` → `6` (OK)
- `GDLTST-9743196400`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `7` → `7` (OK)
