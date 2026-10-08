"""
NOCOPO — Dashboard Reconciliation Log Generator
===============================================
Phase 9: Power BI Dashboard Development
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Run dashboard/reconciliation_expected_values.sql and write dashboard/reconciliation_log.md:
one row per dashboard figure with the SQL value filled in and empty columns for the
dashboard value, the match and the sign-off. This is the Phase 9 exit-gate record
("every figure shown on the dashboard reconciles with its source SQL view/query").

The log is a working document: once someone has typed dashboard values into it, this
script will not overwrite it. Use --force to regenerate (this discards entries), or
write to another file with --output.

Usage
-----
    python python/validation/06_generate_reconciliation_log.py
    python python/validation/06_generate_reconciliation_log.py --output dashboard/reconciliation_log_run2.md
    python python/validation/06_generate_reconciliation_log.py --check     # print the figures only

Connection: the usual PG* environment variables (defaults: localhost, 5433, postgres,
nocopo_db). To prove the query works for the BI role, connect as nocopo_bi:
    set PGUSER=nocopo_bi  (and supply its password through PGPASSWORD or pgpass).
"""

import argparse
import os
import sys
from datetime import datetime
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
QUERY = os.path.join(ROOT, "dashboard", "reconciliation_expected_values.sql")
DEFAULT_OUT = os.path.join(ROOT, "dashboard", "reconciliation_log.md")


def fmt(value, unit):
    """SQL value as the dashboard should display it."""
    v = Decimal(value)
    if unit == "share":
        return f"{v * 100:.2f}%"
    if unit == "ratio":
        return f"{v:.4f}"
    if unit == "index":
        return f"{v:.1f}"
    if unit == "NGN":
        return f"{v:,.0f}"
    if unit == "days":
        return f"{v:,.1f}".rstrip("0").rstrip(".")
    return f"{v:,.0f}" if v == v.to_integral_value() else f"{v:,.1f}"


def main():
    parser = argparse.ArgumentParser(description="Generate the dashboard reconciliation log.")
    parser.add_argument("--output", default=DEFAULT_OUT)
    parser.add_argument("--force", action="store_true", help="overwrite an existing log")
    parser.add_argument("--check", action="store_true", help="print the figures; write nothing")
    args = parser.parse_args()

    with open(QUERY, encoding="utf-8") as fh:
        sql = fh.read()
    conninfo = dict(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5433"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "nocopo_db"),
    )
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        rows = conn.execute(sql).fetchall()
        who = conn.execute("SELECT current_user").fetchone()[0]

    if args.check:
        for r in rows:
            print(" | ".join(str(x) for x in r))
        print(f"{len(rows)} figures")
        return
    if os.path.exists(args.output) and not args.force:
        print(f"{args.output} already exists and may hold sign-offs. Use --force to regenerate "
              f"or --output for another file.")
        sys.exit(1)

    pages = []
    for r in rows:
        if r[1] not in pages:
            pages.append(r[1])
    out = [
        "# Dashboard Reconciliation Log",
        "# Nigeria Public Procurement Intelligence",
        "",
        "> **Phase 9 exit gate:** every figure shown on the dashboard reconciles with its source SQL view/query.",
        f"> **SQL values generated:** {datetime.now():%Y-%m-%d %H:%M} from `{conninfo['dbname']}` "
        f"(role `{who}`) by `python/validation/06_generate_reconciliation_log.py`  ",
        "> **Source query:** `dashboard/reconciliation_expected_values.sql`  ",
        "> **Measure definitions:** `dashboard/README.md` §6  ",
        f"> **Figures:** {len(rows)}",
        "",
        "## How to use",
        "",
        "1. Refresh the Power BI model (run `sql/04_transformations/04_refresh_snapshot.sql` first if staging or "
        "`core.dim_buyer` changed).",
        "2. Clear every slicer, then set only the filter named in the **Slice** column.",
        "3. Type the value the dashboard shows into **Dashboard value**, in the same format as **SQL value**.",
        "4. **Match** is `yes` when counts, days and bands are identical, NGN amounts agree to the whole naira, and "
        "ratios and shares agree to the displayed precision. Anything else is `NO`: write the cause in **Notes** "
        "and do not publish the page until it is resolved.",
        "5. Sign each row with your initials and the date. If the SQL value is stale (data refreshed), re-run the "
        "source query and update the row.",
        "",
        "A mismatch is a defect in the Power BI model or in the measure, never in the SQL view: the views are "
        "validated by `04_run_validation_suite.py --phase 6`, `--phase 7`, `--phase 8` and `--phase 9`.",
    ]
    for page in pages:
        out += ["", f"## {page}", "",
                "| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |",
                "|---|---|---|---|---|---|---|---|---|---|"]
        for fid, pg, figure, dax, slc, val, unit, n in rows:
            if pg != page:
                continue
            out.append(f"| {fid} | {figure} | {slc} | `{dax}` | {fmt(val, unit)} | {n:,} |  |  |  |  |")
    out += ["", "---", "", "*Generated by `python/validation/06_generate_reconciliation_log.py`. "
            "Raw dataset, stg.* and core.* not modified.*", ""]
    with open(args.output, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out))
    print(f"{len(rows)} figures written to {os.path.relpath(args.output, ROOT)}")


if __name__ == "__main__":
    main()
