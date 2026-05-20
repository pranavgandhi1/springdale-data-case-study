"""Reconciliation script.

Compares the raw Airbyte-loaded tables in SPRINGDALE_RAW.IT_SOURCE against the
transformed marts in SPRINGDALE_ANALYTICS.MARTS, then writes a markdown report
to docs/validation/reconciliation_report.md.

Reads Snowflake credentials from ~/.dbt/profiles.yml (same source dbt uses,
no duplicated credential store).

Run from the repo root:
    python scripts/validate.py
or via the Makefile target:
    make validate

Exit code 0 = all checks pass. 2 = one or more checks failed.
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import snowflake.connector
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
REPORT_PATH = REPO_ROOT / "docs" / "validation" / "reconciliation_report.md"
PROFILES_PATH = Path.home() / ".dbt" / "profiles.yml"

TICKETS_TABLE = "IT_TICKETS"
AGENTS_TABLE = "IT_AGENTS"


def load_credentials() -> dict[str, str]:
    if not PROFILES_PATH.exists():
        print(f"Could not find {PROFILES_PATH}. Set up your dbt profile first.", file=sys.stderr)
        sys.exit(1)
    with open(PROFILES_PATH) as f:
        profiles = yaml.safe_load(f)
    target = profiles["springdale"]["outputs"][profiles["springdale"]["target"]]
    return {
        "account": target["account"],
        "user": target["user"],
        "password": target["password"],
        "warehouse": target["warehouse"],
        "role": target["role"],
    }


def scalar(cur, sql: str) -> Any:
    cur.execute(sql)
    row = cur.fetchone()
    return row[0] if row else None


def run_checks(cur) -> list[dict[str, Any]]:
    checks: list[dict[str, Any]] = []

    raw_tickets = scalar(cur, f"select count(*) from SPRINGDALE_RAW.IT_SOURCE.{TICKETS_TABLE}")
    fct_tickets = scalar(cur, "select count(*) from SPRINGDALE_ANALYTICS.MARTS.FCT_TICKETS")
    checks.append({
        "name": "Ticket row count: raw vs fct_tickets",
        "raw": f"{raw_tickets:,}",
        "transformed": f"{fct_tickets:,}",
        "pass": raw_tickets == fct_tickets,
    })

    raw_agents = scalar(cur, f"select count(*) from SPRINGDALE_RAW.IT_SOURCE.{AGENTS_TABLE}")
    dim_agents = scalar(cur, "select count(*) from SPRINGDALE_ANALYTICS.MARTS.DIM_AGENTS")
    checks.append({
        "name": "Agent row count: raw vs dim_agents",
        "raw": f"{raw_agents:,}",
        "transformed": f"{dim_agents:,}",
        "pass": raw_agents == dim_agents,
    })

    throughput_sum = scalar(cur, "select sum(tickets_created) from SPRINGDALE_ANALYTICS.MARTS.AGG_THROUGHPUT_DAILY")
    checks.append({
        "name": "Throughput tickets_created sum vs fct_tickets count",
        "raw": f"{fct_tickets:,}",
        "transformed": f"{throughput_sum:,}",
        "pass": throughput_sum == fct_tickets,
    })

    demand_sum = scalar(cur, "select sum(tickets_total) from SPRINGDALE_ANALYTICS.MARTS.AGG_DEMAND_MIX")
    checks.append({
        "name": "Demand mix tickets_total sum vs fct_tickets count",
        "raw": f"{fct_tickets:,}",
        "transformed": f"{demand_sum:,}",
        "pass": demand_sum == fct_tickets,
    })

    unmapped_severity = scalar(cur, """
        select count(distinct s.severity_raw)
        from SPRINGDALE_ANALYTICS.STAGING.STG_TICKETS s
        left join SPRINGDALE_ANALYTICS.SEEDS.SEED_ENUM_CANONICAL_SEVERITY m
            on s.severity_raw = m.raw_value
        where s.severity_raw is not null
          and m.severity_label is null
    """)
    checks.append({
        "name": "Severity raw values with no canonical mapping",
        "raw": "0 expected",
        "transformed": str(unmapped_severity),
        "pass": unmapped_severity == 0,
    })

    unmapped_priority = scalar(cur, """
        select count(distinct s.priority_raw)
        from SPRINGDALE_ANALYTICS.STAGING.STG_TICKETS s
        left join SPRINGDALE_ANALYTICS.SEEDS.SEED_ENUM_CANONICAL_PRIORITY m
            on s.priority_raw = m.raw_value
        where s.priority_raw is not null
          and m.priority_label is null
    """)
    checks.append({
        "name": "Priority raw values with no canonical mapping",
        "raw": "0 expected",
        "transformed": str(unmapped_priority),
        "pass": unmapped_priority == 0,
    })

    # For severity comparison we verify the canonicalization via the seed table:
    # the canonical label produced in fct must equal the seed's mapping of the raw value.
    # This correctly handles spelling fixes like "Mayor" → "Major".
    cur.execute(f"""
        with random_raw as (
            select * from SPRINGDALE_RAW.IT_SOURCE.{TICKETS_TABLE} sample (10 rows)
        )
        select
            r.id_ticket,
            r.severity                  as raw_severity,
            s.severity_label            as expected_label,
            f.severity_label            as actual_label,
            r.resolution_time_days_     as raw_res_time,
            f.resolution_time_days      as fct_res_time
        from random_raw r
        left join SPRINGDALE_ANALYTICS.SEEDS.SEED_ENUM_CANONICAL_SEVERITY s
            on r.severity = s.raw_value
        join SPRINGDALE_ANALYTICS.MARTS.FCT_TICKETS f
            on r.id_ticket = f.ticket_id
    """)
    sample_rows = cur.fetchall()
    spot_pass = len(sample_rows) > 0
    spot_details: list[str] = []
    for raw_id, raw_sev, expected_lbl, actual_lbl, raw_rt, fct_rt in sample_rows:
        sev_match = expected_lbl == actual_lbl
        # Raw values may come back as Decimal/str depending on column type;
        # compare as integers since both ultimately represent day counts.
        try:
            rt_match = int(raw_rt) == int(fct_rt)
        except (TypeError, ValueError):
            rt_match = raw_rt == fct_rt
        ok = sev_match and rt_match
        spot_pass = spot_pass and ok
        status_sev = "OK" if sev_match else "MISMATCH"
        status_rt = "OK" if rt_match else "MISMATCH"
        spot_details.append(
            f"- `{raw_id}`: severity `{raw_sev}` → expected `{expected_lbl}`, actual `{actual_lbl}` ({status_sev}); "
            f"resolution_time `{raw_rt}` → `{fct_rt}` ({status_rt})"
        )

    checks.append({
        "name": "Spot-check 10 random tickets (severity mapping + resolution_time preserved)",
        "raw": f"{len(sample_rows)} sampled",
        "transformed": f"{len(sample_rows)} verified" if spot_pass else "MISMATCH",
        "pass": spot_pass,
        "details": spot_details,
    })

    return checks


def write_report(checks: list[dict[str, Any]]) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Reconciliation Report",
        "",
        f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
        "",
        "Compares raw Airbyte-loaded tables in `SPRINGDALE_RAW.IT_SOURCE` against "
        "the transformed marts in `SPRINGDALE_ANALYTICS.MARTS`. Each check is "
        "either a row-count equality, an aggregate match, or a value-level spot check.",
        "",
        "## Summary",
        "",
        "| Check | Raw | Transformed | Result |",
        "|---|---|---|---|",
    ]
    for c in checks:
        status = "PASS" if c["pass"] else "**FAIL**"
        lines.append(f"| {c['name']} | {c['raw']} | {c['transformed']} | {status} |")

    spot = next((c for c in checks if c["name"].startswith("Spot-check")), None)
    if spot and spot.get("details"):
        lines.extend(["", "## Spot-check detail", ""])
        lines.extend(spot["details"])

    lines.append("")
    REPORT_PATH.write_text("\n".join(lines))
    print(f"Report written to {REPORT_PATH}")


def main() -> None:
    creds = load_credentials()
    with snowflake.connector.connect(**creds) as conn:
        cur = conn.cursor()
        try:
            checks = run_checks(cur)
        finally:
            cur.close()

    write_report(checks)

    if not all(c["pass"] for c in checks):
        print("One or more reconciliation checks FAILED. See report.", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
