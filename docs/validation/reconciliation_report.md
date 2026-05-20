# Reconciliation Report

Generated: 2026-05-20 03:50:38 UTC

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

- `TMLESR-4643108389`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `6` → `6` (OK)
- `SHLEER-3343991333`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `3` → `3` (OK)
- `GMLTNR-4143376975`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `1` → `1` (OK)
- `GHLEER-4742385140`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `7` → `7` (OK)
- `KHLENR-1144062826`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `1` → `1` (OK)
- `GMLTSR-7943266311`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `4` → `4` (OK)
- `GHLTST-3043136601`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `10` → `10` (OK)
- `THLTER-2343773194`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `3` → `3` (OK)
- `TDLTNR-6043472754`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `0` → `0` (OK)
- `SHLEST-1344173322`: severity `2 - Normal` → expected `Normal`, actual `Normal` (OK); resolution_time `3` → `3` (OK)
