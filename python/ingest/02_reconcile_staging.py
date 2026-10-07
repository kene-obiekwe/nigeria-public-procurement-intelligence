"""
NOCOPO / OCDS Dataset — Source-to-Staging Reconciliation
========================================================
Phase 5: PostgreSQL Staging Implementation (exit-gate test)
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Independently recount the raw OCDS file and compare it with what is in
stg.*. This script deliberately does NOT reuse the loader's row builders.
Each expectation is derived from a separate traversal of the JSON.

Checks
------
1. Row counts per staging table (source vs staging; Phase 4 expectation shown)
2. Distinct OCIDs, release_seq uniqueness
3. Monetary totals per table (exact Decimal equality)
4. Non-null date counts per date column
5. DQ flag distributions: SQL-generated flags vs rules re-applied in Python
6. Referential checks (orphans) and raw-file checksum

Usage
-----
    python python/ingest/02_reconcile_staging.py

Output
------
    docs/phase5_staging_results.md   (context: docs/phase5_staging_reconciliation.md)
    Exit code 1 if any check fails.
"""

import hashlib
import json
import os
import sys
from collections import Counter
from datetime import datetime
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "NOCOPO dataset", "all07010.json")
OUTPUT = os.path.join(ROOT, "docs", "phase5_staging_results.md")
EXPECTED_SHA256 = "615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c"

# Phase 4 v1.1 expectations (documented, not measured here)
PHASE4_EXPECTED = {
    "stg.releases": "108,277", "stg.planning": "108,277", "stg.tender": "18,408",
    "stg.awards": "17,417", "stg.award_suppliers": "~17,441", "stg.contracts": "17,043",
    "stg.transactions": "~13,617", "stg.milestones": "42,854", "stg.parties": "~216,514",
}


def date_flag(v):
    """Python re-implementation of stg.fn_date_quality_flag (DQ-08/09)."""
    if not v:
        return None
    d = v[:10]
    if d == "2001-01-01":
        return "PLACEHOLDER"
    if d >= "2051-01-01":
        return "IMPOSSIBLE"
    if d >= "2026-01-01":
        return "FUTURE"
    return "VALID"


def tenderer_flag(n):
    return "ANOMALOUS" if n > 1000 else "ELEVATED" if n > 100 else "NORMAL"


def source_profile(releases):
    """Independent traversal of the raw releases."""
    cnt, money, dates, flags = Counter(), Counter(), Counter(), Counter()
    ocids = set()

    def m(key, obj):
        a = (obj or {}).get("amount")
        if a is not None:
            money[key] += a
            if a == 0:
                flags[(key + "_monetary_flag", "ZERO_VALUE")] += 1
        return a

    def dt(key, v):
        if v:
            dates[key] += 1
        f = date_flag(v)
        if f:
            flags[(key + "_flag", f)] += 1

    for r in releases:
        cnt["stg.releases"] += 1
        cnt["stg.planning"] += 1
        ocids.add(r["ocid"])
        if not r.get("parties"):
            flags[("party_flag", "NO_PARTIES")] += 1
        b = (r.get("planning") or {}).get("budget") or {}
        a = m("budget", b.get("amount"))
        if a is not None and a >= Decimal("1e12"):
            flags[("budget_amount_flag", "EXTREME")] += 1
        if r.get("tender"):
            t = r["tender"]
            cnt["stg.tender"] += 1
            m("tender_value", t.get("value"))
            flags[("tenderer_count_flag", tenderer_flag(t["numberOfTenderers"]))] += 1
            dt("tender_start_date", (t.get("tenderPeriod") or {}).get("startDate"))
            dt("tender_end_date", (t.get("tenderPeriod") or {}).get("endDate"))
        for aw in r.get("awards", []):
            cnt["stg.awards"] += 1
            cnt["stg.award_suppliers"] += len(aw.get("suppliers", []))
            a = m("award", aw.get("value"))
            if a is not None and a >= Decimal("1e12"):
                flags[("award_value_flag", "EXTREME")] += 1
            dt("award_date", aw.get("date"))
        for c in r.get("contracts", []):
            cnt["stg.contracts"] += 1
            m("contract", c.get("value"))
            dt("date_signed", c.get("dateSigned"))
            dt("period_start_date", (c.get("period") or {}).get("startDate"))
            dt("period_end_date", (c.get("period") or {}).get("endDate"))
            impl = c.get("implementation") or {}
            if impl.get("transactions") or impl.get("milestones"):
                cnt["contracts_with_implementation"] += 1
            for x in impl.get("transactions", []):
                cnt["stg.transactions"] += 1
                m("transaction", x.get("value"))
            for ms in c.get("milestones", []) + impl.get("milestones", []):
                cnt["stg.milestones"] += 1
                dt("due_date", ms.get("dueDate"))
                dt("date_met", ms.get("dateMet"))
        for p in r.get("parties") or []:
            cnt["stg.parties"] += 1
            if "supplier" in p.get("roles", []) and p.get("id") == "NG-BPP-":
                flags[("supplier_id_flag", "INCOMPLETE")] += 1
    return cnt, len(ocids), money, dates, flags


STAGING_SQL = {
    "count": "SELECT count(*) FROM {t}",
    "money": {
        "budget": "SELECT coalesce(sum(budget_amount),0) FROM stg.planning",
        "tender_value": "SELECT coalesce(sum(tender_value_amount),0) FROM stg.tender",
        "award": "SELECT coalesce(sum(award_value_amount),0) FROM stg.awards",
        "contract": "SELECT coalesce(sum(contract_value_amount),0) FROM stg.contracts",
        "transaction": "SELECT coalesce(sum(transaction_value),0) FROM stg.transactions",
    },
    "dates": {
        "tender_start_date": "stg.tender", "tender_end_date": "stg.tender",
        "award_date": "stg.awards", "date_signed": "stg.contracts",
        "period_start_date": "stg.contracts", "period_end_date": "stg.contracts",
        "due_date": "stg.milestones", "date_met": "stg.milestones",
    },
    "flags": {
        "party_flag": "stg.releases", "budget_amount_flag": "stg.planning",
        "budget_monetary_flag": "stg.planning", "tenderer_count_flag": "stg.tender",
        "tender_value_monetary_flag": "stg.tender", "tender_start_date_flag": "stg.tender",
        "tender_end_date_flag": "stg.tender", "award_value_flag": "stg.awards",
        "award_monetary_flag": "stg.awards", "award_date_flag": "stg.awards",
        "contract_monetary_flag": "stg.contracts", "date_signed_flag": "stg.contracts",
        "period_start_date_flag": "stg.contracts", "period_end_date_flag": "stg.contracts",
        "transaction_monetary_flag": "stg.transactions", "due_date_flag": "stg.milestones",
        "date_met_flag": "stg.milestones", "supplier_id_flag": "stg.parties",
    },
    "orphans": {
        "planning without release": "SELECT count(*) FROM stg.planning p LEFT JOIN stg.releases r USING (release_id) WHERE r.release_id IS NULL",
        "contracts whose award is missing": "SELECT count(*) FROM stg.contracts c LEFT JOIN stg.awards a USING (award_id) WHERE a.award_id IS NULL",
        "contracts whose award is in another release": "SELECT count(*) FROM stg.contracts c JOIN stg.awards a USING (award_id) WHERE a.release_id <> c.release_id",
        "award_suppliers without award": "SELECT count(*) FROM stg.award_suppliers s LEFT JOIN stg.awards a USING (award_id) WHERE a.award_id IS NULL",
        "transactions without contract": "SELECT count(*) FROM stg.transactions x LEFT JOIN stg.contracts c USING (contract_id) WHERE c.contract_id IS NULL",
        "milestones without contract": "SELECT count(*) FROM stg.milestones m LEFT JOIN stg.contracts c USING (contract_id) WHERE c.contract_id IS NULL",
        "parties without release": "SELECT count(*) FROM stg.parties p LEFT JOIN stg.releases r USING (release_id) WHERE r.release_id IS NULL",
    },
}

def main():
    with open(SOURCE, "rb") as fh:
        checksum = hashlib.sha256(fh.read()).hexdigest()
    with open(SOURCE, encoding="utf-8") as fh:
        releases = json.load(fh, parse_float=Decimal)["releases"]
    cnt, n_ocids, money, dates, flags = source_profile(releases)

    conninfo = dict(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5433"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "nocopo_db"),
    )
    results, failures = [], 0

    def check(section, name, source, staging):
        nonlocal failures
        ok = source == staging
        failures += not ok
        results.append((section, name, source, staging, "✓" if ok else "✗ FAIL"))

    with psycopg.connect(**conninfo) as conn, conn.cursor() as cur:
        q = lambda sql: cur.execute(sql).fetchone()[0]
        server = q("SHOW server_version")
        for t in PHASE4_EXPECTED:
            check("Row counts", t, cnt[t], q(STAGING_SQL["count"].format(t=t)))
        check("Identity", "distinct OCIDs", n_ocids, q("SELECT count(DISTINCT ocid) FROM stg.releases"))
        check("Identity", "distinct release_seq", cnt["stg.releases"],
              q("SELECT count(DISTINCT release_seq) FROM stg.releases"))
        check("Identity", "contracts with has_implementation", cnt["contracts_with_implementation"],
              q("SELECT count(*) FROM stg.contracts WHERE has_implementation"))
        for k, sql in STAGING_SQL["money"].items():
            check("Monetary totals (NGN)", k, money[k], q(sql))
        for col, t in STAGING_SQL["dates"].items():
            check("Non-null dates", f"{t}.{col}", dates[col], q(f"SELECT count({col}) FROM {t}"))
        for col, t in STAGING_SQL["flags"].items():
            cur.execute(f"SELECT {col}, count(*) FROM {t} WHERE {col} IS NOT NULL GROUP BY 1 ORDER BY 1")
            staged = dict(cur.fetchall())
            expected = {v: n for (f, v), n in flags.items() if f == col}
            for value in sorted(set(staged) | set(expected)):
                check("DQ flags (SQL generated vs Python rule)", f"{t}.{col} = {value}",
                      expected.get(value, 0), staged.get(value, 0))
        for name, sql in STAGING_SQL["orphans"].items():
            check("Referential integrity", name, 0, q(sql))
    check("Raw data protection", "source SHA-256 matches pinned checksum", EXPECTED_SHA256, checksum)

    out = [
        "# Phase 5 — Staging Reconciliation Results",
        "",
        "> **Script:** `python/ingest/02_reconcile_staging.py`  ",
        f"> **Run date:** {datetime.now():%Y-%m-%d %H:%M:%S}  ",
        f"> **Database:** `{conninfo['dbname']}` on {conninfo['host']}:{conninfo['port']} (PostgreSQL {server})  ",
        f"> **Result:** {'ALL CHECKS PASSED' if not failures else f'{failures} CHECK(S) FAILED'} "
        f"({len(results)} checks)",
        "",
        "Source values come from an independent traversal of the raw JSON. Staging values come",
        "from SQL against `stg.*`. Context and interpretation are in",
        "`docs/phase5_staging_reconciliation.md`.",
        "",
    ]
    section = None
    for sec, name, src, stg, status in results:
        if sec != section:
            section = sec
            out += ["", f"## {sec}", ""]
            if sec == "Row counts":
                out += ["| Table | Phase 4 expectation | Source | Staging | Status |", "|---|---|---|---|---|"]
            else:
                out += ["| Check | Source | Staging | Status |", "|---|---|---|---|"]
        fmt = lambda v: f"{v:,}" if isinstance(v, (int, Decimal)) else f"`{v}`"
        if sec == "Row counts":
            out.append(f"| `{name}` | {PHASE4_EXPECTED[name]} | {fmt(src)} | {fmt(stg)} | {status} |")
        else:
            out.append(f"| `{name}` | {fmt(src)} | {fmt(stg)} | {status} |")
    out += ["", "---", "", "*Generated by `python/ingest/02_reconcile_staging.py`. Raw dataset not modified.*", ""]
    with open(OUTPUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
    print(f"{len(results)} checks, {failures} failed. Report: {OUTPUT}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
