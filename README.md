# Springdale IT Ticket Operations — Case Study

End-to-end analytics pipeline on 97,498 IT tickets across 50 agents.
**Google Sheets → Airbyte → Snowflake → dbt → Hex.**

> **🔗 Live dashboard: [Springdale IT Ticket Operations on Hex](https://app.hex.tech/019e3c66-087e-766b-a959-a77169bfb457/app/Data-Case-Study-Pranav-Gandhi-033Jmxn3gK7Vbdx0neh7C2/latest)**
>
> The dashboard is the deliverable. This README documents the pipeline, decisions, and assumptions behind it.

---

## The story

Springdale's IT team handles ~600 tickets/week — 2.4× the volume of five years ago — and closures have tracked creations the entire time. The team meets the 3-day SLA on 48% of tickets. Inside that operationally-stable picture, four things matter:

1. **Backlog is steady-state, not growing.** Closures have tracked creations through two distinct step-changes in volume (2018, 2020). The 2.4× demand growth has been absorbed without capacity erosion; cumulative backlog drifted ~150 → ~400 but never ran away. The two step-changes are the moments worth diligencing with management — what drove them, and was hiring lockstep?
2. **Hardware is the bottleneck.** 8-day median resolution and ~80% SLA breach despite being only 10% of volume. Bringing Hardware + System (4× the volume) down to Software's breach rate lifts overall SLA from 48% → ~56% with no headcount change.
3. **Major tickets miss SLA more often than Minor.** Urgent hits SLA 79% of the time, but Major sits at 51% — worse than Minor (64%) and Unclassified (70%). Prioritization is over-weighting Urgent at Major's expense.
4. **~30% of tickets enter the queue with no priority assigned at every severity tier**, including 29% of Urgent tickets. This is a systemic intake gap — fixing it once at intake unlocks accountability across the queue.

**Supporting:** workload is evenly distributed across all 50 agents (top quartile = 1.14× bottom quartile) — no hero-agent risk, but productivity gains have to come from process, not from cloning top performers.

---

## Architecture

```
┌──────────────────┐    ┌─────────┐    ┌──────────────────────┐    ┌──────┐    ┌─────┐
│ Google Sheets    │───▶│ Airbyte │───▶│ Snowflake            │───▶│ dbt  │───▶│ Hex │
│ (2 tabs:         │    │ Cloud   │    │ SPRINGDALE_RAW       │    │ Core │    │ App │
│  it_tickets,     │    │ full    │    │   .IT_SOURCE         │    │      │    │     │
│  it_agents)      │    │ refresh │    │ SPRINGDALE_ANALYTICS │    │      │    │     │
│                  │    │ +       │    │   .STAGING           │    │      │    │     │
│                  │    │ dedupe  │    │   .INTERMEDIATE      │    │      │    │     │
│                  │    │         │    │   .MARTS             │    │      │    │     │
└──────────────────┘    └─────────┘    └──────────────────────┘    └──────┘    └─────┘
       source              extract-load            warehouse        transform     BI
```

**Three-layer dbt architecture:** staging (1:1 source cleanup + typing) → intermediate (`int_tickets_enriched` carries all business logic — SLA join, data-quality flags, calendar derivations) → marts (one fact, one dim, eight aggregate marts feeding Hex).

---

## Implementation outline

| Phase | What | Output |
|---|---|---|
| 1. Source survey | Inspect the Google Sheet, document misspelled enums (`Unclasified`, `Mayor`, `Unassiged`), confirm row count and field semantics | `docs/internal/source-audit.md` |
| 2. Warehouse setup | Provision Snowflake roles, warehouse, raw + analytics databases | `dbt/setup/snowflake_setup.sql` |
| 3. Airbyte extract-load | Configure service-account-authenticated sync from native Google Sheet into `SPRINGDALE_RAW.IT_SOURCE`, full refresh + overwrite | `airbyte/connection-config.md` |
| 4. dbt staging | 1:1 source models with snake_case typing, no business logic | `dbt/models/staging/` |
| 5. Enum canonicalization | CSV seeds map raw misspelled values to canonical labels; raw values preserved | `dbt/seeds/seed_enum_canonical_*.csv` |
| 6. Intermediate enrichment | Single business-logic model: SLA threshold join, breach flag, data-quality flags, calendar fields, derived `closed_date` | `dbt/models/intermediate/int_tickets_enriched.sql` |
| 7. Marts | One fact + one dim + eight aggregate marts, one per Hex chart family | `dbt/models/marts/` |
| 8. Tests | Schema tests (`unique`, `not_null`, `relationships`, `accepted_values`) + nine custom recon and outlier tests | `dbt/models/*/_*.yml`, `dbt/tests/*.sql` |
| 9. Reconciliation | Python script comparing raw row counts and spot-checked values against marts | `scripts/validate.py`, `docs/validation/reconciliation_report.md` |
| 10. Hex app | Six-section dashboard wired to mart tables only — no raw or staging refs from BI | (published, link above) |
| 11. Writeup | This README + design-decisions notes | `README.md`, `docs/internal/design-decisions-notes.md` |

---

## KPI catalog

**Required KPIs (per case study spec):**

| # | KPI | Mart | Notes |
|---|---|---|---|
| 1 | Ticket mix by severity and priority | `agg_severity_priority_mix` | Cross-tab with % within severity to expose the unassigned-priority gap |
| 2 | Tickets resolved per agent per week | `agg_tickets_per_agent_per_week` | Weekly grain on derived `closed_date` |
| 3 | Median resolution time by issue type | `agg_resolution_by_category` | Interpreted as `request_category` (Hardware/Software/System/Login Access) rather than the binary `issue_type` — see Design Decisions |
| 4 | SLA compliance rate (≤3 days) | `agg_resolution_by_severity`, `fct_tickets.is_sla_breach` | Flat 3-day threshold, configurable via dbt var `sla_threshold_days` |

**Added KPIs:**

| KPI | Mart | Why it earns its place |
|---|---|---|
| Agent performance — speed × CSAT × volume | `agg_agent_performance` | Identifies four operational archetypes for staffing/coaching decisions |
| Demand decomposition | `agg_demand_mix` | Shows where workload originates by category + issue type |
| Weekly throughput vs demand + backlog trend | `agg_throughput_daily` (rolled up to weekly in a Hex SQL cell) | Answers "is the team keeping pace with demand?" — the question behind every PE staffing decision. Charted as grouped bars (tickets created vs closed) with a cumulative-backlog area on a secondary axis |
| Weekly data-quality scorecard | `agg_data_quality_weekly` | Trends the intake-gap metrics that gate trust in every other KPI |

---

## Key findings

### 1. Backlog is steady-state — the team scaled with the load

| Window | Demand (tickets/week) | Cumulative backlog |
|---|---|---|
| 2016 | ~250 | ~150 |
| 2020 | ~600 | ~400 |
| Growth | **2.4×** | drifted, did not run away |

Closures tracked creations almost perfectly across two step-changes in volume (2018 and 2020). There are no sustained "create > close" periods that would signal structural under-capacity; the queue is a steady-state buffer, not a growing liability. **The two step-changes are the moments worth diligencing with management** — what drove them, and was hiring lockstep with demand?

This finding reframes everything below. The SLA problem is not "the team is drowning." It's a specific structural drag on Hardware tickets inside an otherwise operationally-stable team.

### 2. Hardware drag — the largest, most actionable opportunity

| Category | Volume | Median resolution (days) | SLA breach rate |
|---|---|---|---|
| Login Access | 29,193 | <1 | ~0% |
| Software | 19,570 | 4 | ~62% |
| System | 39,002 | 6 | ~78% |
| **Hardware** | **9,733** | **8** | **~80%** |

Hardware is 10% of volume but resolves 8× slower than Login Access. Bringing Hardware to Software's breach rate (62%) lifts overall SLA ~2 points; doing the same for System (4× the volume) adds another ~6 points. Combined: **48% → ~56% with no headcount change.**

### 3. The Major / Urgent SLA inversion

| Severity | SLA hit rate |
|---|---|
| Urgent | 79% |
| Unclassified | 70% |
| Minor | 64% |
| **Major** | **51%** |
| Normal | (bulk of volume — driven by category, not severity) |

Major hits SLA less often than Minor. Prioritization is tunneling on Urgent at Major's expense — either redefine the severity threshold or rebalance staffing on the Major queue.

### 4. The intake-priority gap

~30% of tickets at **every** severity tier have no priority assigned, including 29% of Urgent. This is a systemic intake problem, not a tier-specific one. Making priority a required field at intake unlocks SLA accountability on ~30% of the queue overnight.

### Supporting: workload is evenly distributed — no hero-agent risk

| Metric | Value |
|---|---|
| Top 3 agents' share of total volume | 6.2% |
| Top quartile share | 26.6% |
| Bottom quartile share | 23.4% |
| Top quartile / bottom quartile ratio | 1.14× |
| Team size | 50 agents |

The bench is deep and interchangeable. This de-risks attrition but also constrains the recommendation set: productivity gains have to come from process change (the Hardware fix in Finding 2) or from intake hygiene (Finding 4) — not from cloning top performers or pushing harder on the existing roster, because there are no meaningful gaps in throughput to close.

### Bonus: data-quality findings worth flagging

- **CSAT is 100% populated** — unusual enough to suggest default values rather than collected responses. The 4.10 average should not be trusted until methodology is validated.
- **Every single source row uses misspelled enums** (`0 - Unclasified`, `3 - Mayor`, `0 - Unassiged`). Not a mix — all 97,498. Canonicalized via versioned seed; raw values preserved.

---

## Key design decisions

**1. Three-layer architecture (staging / intermediate / marts), not flat staging → marts.**
Even though current scope has one fact table, all business logic (SLA join, breach flag, data-quality flags, calendar derivations) lives in `int_tickets_enriched`. If SLA tier definitions change, only the seed updates and the intermediate recomputes — every downstream mart picks up the change with zero refactor. Trade-off: ~2s extra build time and three extra files. Worth it for any pipeline expecting future scope (additional facts, snapshots, second sources).

**2. Flag, do not fix, data quality issues.**
Misspelled enums, unclassified severities, and unassigned priorities are surfaced as boolean columns on `fct_tickets` rather than silently corrected or dropped. The "% Unclassified Severity" KPI is only meaningful because rows weren't backfilled. PE operators need to see the broken state, not the cleaned one. Source data in `SPRINGDALE_RAW` is never modified.

**3. Seeds for business rules (enum canonicalization).**
Source-enum canonicalization lives in CSV seeds (`seed_enum_canonical_severity.csv`, `seed_enum_canonical_priority.csv`), not in macros or hardcoded SQL. Non-engineer business owners can read and edit; changes are version-controlled and auditable; the rest of the pipeline references them via `{{ ref() }}` like any other model.

**4. `request_category` for KPI #3, not `issue_type`.**
The case study asks for "average resolution time per issue type." The source has two candidates: `issue_type` (binary: IT Error vs IT Request) and `request_category` (4 values: Hardware/Software/System/Login Access). `request_category` is used because the binary field is too coarse to drive staffing or triage decisions — it can't distinguish a Hardware queue back-up from a Login Access one. `request_category` maps cleanly to skills/teams and reveals the Hardware outlier that's actually actionable.

**5. Single flat 3-day SLA threshold, configurable.**
Per the case study spec, SLA is a flat 3 days for all tickets — not severity-tiered. Implemented as dbt var `sla_threshold_days` so it can be overridden at runtime without code changes. Tiered SLAs (Urgent ≤ 2d, Major ≤ 3d, Normal ≤ 5d, Minor ≤ 7d) were considered and rejected to align with the explicit spec and avoid two competing "SLA" concepts in the dashboard.

---

## Assumptions

- **`resolution_time_days` is elapsed days, not business days.** The source has no clarifying definition; elapsed is the simpler and more conservative read.
- **`closed_date = created_date + resolution_time_days`.** The source has no explicit close timestamp; this derived field powers all weekly throughput, daily backlog, and trend analytics. Documented as derived in `fct_tickets`.
- **SLA threshold = 3 days flat** (per spec), configurable via `sla_threshold_days`.
- **CSAT 1–5 scale is treated as ordinal** for averages, knowing the 100% populated rate makes those averages suspect (flagged in the dashboard).
- **The three misspelled source enums are preserved in raw and canonicalized via seed.** Not silently corrected.
- **One fiscal calendar, no holiday adjustments.** Date math treats weekends and holidays as ordinary days.

---

## Setup & reproduce

### Prerequisites

- Snowflake account (any edition with role/warehouse permissions)
- Airbyte Cloud account (free tier sufficient)
- GCP project with a service account (Sheets API + Drive API enabled)
- Python 3.10+
- dbt Core 1.7+ with the Snowflake adapter

### One-time setup

```bash
# 1. Clone
git clone https://github.com/pranavgandhi1/springdale-data-case-study.git
cd springdale-data-case-study

# 2. Provision Snowflake objects (run as ACCOUNTADMIN in Snowsight)
#    Creates: SPRINGDALE_RAW + SPRINGDALE_ANALYTICS databases,
#             LOADER_ROLE + TRANSFORMER_ROLE, TRANSFORM_WH
cat dbt/setup/snowflake_setup.sql   # review, then run in Snowsight

# 3. Configure Airbyte source/destination/connection
#    Follow airbyte/connection-config.md step by step

# 4. Install Python deps for the reconciliation script
python -m venv .venv && source .venv/bin/activate
pip install -r scripts/requirements.txt

# 5. Configure dbt profile (~/.dbt/profiles.yml)
#    See dbt/profiles.example.yml for the template
```

### Running the pipeline

```bash
make setup       # dbt deps + dbt debug (verifies profile + warehouse connectivity)
make seed        # load canonical enum mappings
make build       # dbt build (runs seeds + models + tests in DAG order)
make validate    # python reconciliation script: raw vs marts
make docs        # generates and serves dbt docs at http://localhost:8080
```

### Connecting Hex

Point Hex at `SPRINGDALE_ANALYTICS.MARTS` using a read-only role. The dashboard queries mart tables only — no raw or staging dependencies from BI.

---

## What I'd do differently with more time

- **Normalize the agent performance view for ticket-mix specialization.** An agent who only handles Login Access *should* look fast and satisfying — that's not skill, it's ticket mix. A category-weighted comparison would defuse this.
- **Build a snapshot of `agg_throughput_daily`** so backlog trend is reproducible against a frozen point-in-time view, not just the current window.
- **Validate CSAT collection methodology with the business owner** before publishing the 4.10 average. The 100% completion rate is highly suspicious.
- **Add CI** (GitHub Actions running `dbt build` against a PR-specific schema in Snowflake) for any future contributor.
- **Production-grade environment separation:** per-developer schemas, separate prod database, deploy via merge-to-main automation. Skipped here per case-study scope (single developer, no production users).

---

## Hours spent

| Phase | Hours |
|---|---|
| Source survey + warehouse setup + Airbyte extract-load | 0.75 |
| dbt staging + intermediate + marts | 1.00 |
| Tests + reconciliation | 0.75 |
| Hex dashboard build | 1.25 |
| Writeup (this README + ADRs) | 0.25 |
| QA + iteration (dashboard polish, spot-checking after publish) | 0.50 |
| **Total** | **4.50** |

Came in under the 5-hour cap set by the case study brief.

---

## Repo tour

```
.
├── README.md                              ← you are here
├── Makefile                               ← one-line entry points (setup/seed/run/test/build/validate)
├── airbyte/
│   └── connection-config.md               ← reproducible Airbyte source/destination/connection settings
├── dbt/
│   ├── dbt_project.yml
│   ├── setup/
│   │   └── snowflake_setup.sql            ← one-time Snowflake DDL (roles, warehouse, databases)
│   ├── seeds/
│   │   ├── seed_enum_canonical_severity.csv  ← raw → canonical severity mapping
│   │   └── seed_enum_canonical_priority.csv  ← raw → canonical priority mapping
│   ├── models/
│   │   ├── staging/                       ← 1:1 source cleanup, typing, snake_case
│   │   ├── intermediate/
│   │   │   └── int_tickets_enriched.sql   ← single business-logic model: SLA, flags, calendar
│   │   └── marts/
│   │       ├── dim_agents.sql
│   │       ├── fct_tickets.sql            ← wide ticket fact with denormalized agent attributes
│   │       ├── agg_severity_priority_mix.sql       ← Required KPI 1
│   │       ├── agg_tickets_per_agent_per_week.sql  ← Required KPI 2
│   │       ├── agg_resolution_by_category.sql      ← Required KPI 3
│   │       ├── agg_resolution_by_severity.sql      ← Required KPI 4
│   │       ├── agg_agent_performance.sql           ← added: agent quadrants
│   │       ├── agg_demand_mix.sql                  ← added: demand decomposition
│   │       ├── agg_throughput_daily.sql            ← added: throughput + cumulative backlog
│   │       └── agg_data_quality_weekly.sql         ← added: weekly DQ scorecard
│   ├── tests/                             ← nine custom tests: recon row-counts, seed coverage, outlier warns
│   └── macros/
│       └── generate_schema_name.sql       ← target-aware schema routing
├── scripts/
│   ├── requirements.txt
│   └── validate.py                        ← raw vs marts reconciliation, writes to docs/validation/
└── docs/
    ├── internal/
    │   └── design-decisions-notes.md      ← longform ADR notes (source for this README's decisions section)
    └── validation/
        └── reconciliation_report.md       ← generated by scripts/validate.py
```
