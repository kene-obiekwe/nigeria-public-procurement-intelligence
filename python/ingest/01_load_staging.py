"""
NOCOPO / OCDS Dataset — Staging Loader
======================================
Phase 5: PostgreSQL Staging Implementation
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Parse the raw OCDS release package and load it into the source-faithful
staging tables (stg.*) defined in sql/02_schema/00_draft_core_schema.sql.

Loading rules
-------------
- The raw file is opened read-only; its SHA-256 is checked before and after.
- Monetary values are parsed as Decimal (no float rounding) into NUMERIC(30,4).
- Dates are loaded as DATE only after confirming the time part is exactly
  T00:00:00Z, so the cast loses nothing. Any other time part stops the load.
- Data-quality flags are NOT computed here. They are GENERATED columns in
  PostgreSQL, so every classification rule lives in SQL.
- The whole load runs in one transaction. Staging tables are truncated first,
  so the script can be re-run, and a failure leaves staging unchanged.

Connection
----------
Standard libpq environment variables, with project defaults:
    PGHOST=localhost  PGPORT=5433  PGUSER=postgres  PGDATABASE=nocopo_db
The password is read by libpq from pgpass.conf (never passed on the command line).

Usage
-----
    python python/ingest/01_load_staging.py
"""

import hashlib
import json
import os
import sys
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "NOCOPO dataset", "all07010.json")
EXPECTED_SHA256 = "615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c"

STAGING_TABLES = [
    "stg.milestones", "stg.transactions", "stg.contracts", "stg.award_suppliers",
    "stg.awards", "stg.tender", "stg.planning", "stg.parties", "stg.releases",
]


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def to_date(value, field):
    """'YYYY-MM-DDT00:00:00Z' -> 'YYYY-MM-DD'. Refuses any other time part."""
    if not value:
        return None
    if len(value) != 20 or not value.endswith("T00:00:00Z"):
        raise ValueError(f"{field}: unexpected date format {value!r}; casting to DATE would lose data")
    return value[:10]


def amount(obj):
    return (obj or {}).get("amount")


def currency(obj):
    return (obj or {}).get("currency")


def text(value):
    return None if value is None else str(value)


# ------------------------------------------------------------------
# Row builders — one generator per staging table
# ------------------------------------------------------------------
def build_rows(releases):
    rows = {t: [] for t in STAGING_TABLES}
    for r in releases:
        rid = r["id"]
        buyer = r.get("buyer") or {}
        rows["stg.releases"].append((
            rid, r["ocid"], r.get("date"), r.get("tag") or [],
            r.get("initiationType"), r.get("language"),
            buyer.get("id"), buyer.get("name"),
            None if r.get("parties") else "NO_PARTIES",
        ))

        budget = (r.get("planning") or {}).get("budget") or {}
        rows["stg.planning"].append((
            rid, text(budget.get("id")), text(budget.get("projectID")),
            amount(budget.get("amount")), currency(budget.get("amount")),
            budget.get("description"), budget.get("project"),
        ))

        t = r.get("tender")
        if t:
            period = t.get("tenderPeriod") or {}
            rows["stg.tender"].append((
                rid, text(t.get("id")), t.get("title"), t.get("description"), t.get("status"),
                t.get("procurementMethod"), t.get("procurementMethodDetails"),
                t.get("procurementMethodRationale"), t.get("numberOfTenderers"),
                amount(t.get("value")), currency(t.get("value")),
                to_date(period.get("startDate"), "tender.tenderPeriod.startDate"),
                to_date(period.get("endDate"), "tender.tenderPeriod.endDate"),
                t.get("awardCriteria"), t.get("awardCriteriaDetails"), t.get("hasEnquiries"),
                t.get("submissionMethod"), t.get("submissionMethodDetails"),
            ))

        for a in r.get("awards", []):
            rows["stg.awards"].append((
                text(a["id"]), rid, a.get("title"), a.get("description"), a.get("status"),
                to_date(a.get("date"), "awards.date"),
                amount(a.get("value")), currency(a.get("value")),
            ))
            for seq, s in enumerate(a.get("suppliers", []), start=1):
                rows["stg.award_suppliers"].append((text(a["id"]), seq, s.get("id"), s.get("name")))

        for c in r.get("contracts", []):
            impl = c.get("implementation") or {}
            period = c.get("period") or {}
            cid = text(c["id"])
            rows["stg.contracts"].append((
                cid, rid, text(c.get("awardID")), c.get("title"), c.get("description"), c.get("status"),
                amount(c.get("value")), currency(c.get("value")),
                to_date(c.get("dateSigned"), "contracts.dateSigned"),
                to_date(period.get("startDate"), "contracts.period.startDate"),
                to_date(period.get("endDate"), "contracts.period.endDate"),
                bool(impl.get("transactions") or impl.get("milestones")),
            ))
            for x in impl.get("transactions", []):
                payer, payee = x.get("payer") or {}, x.get("payee") or {}
                rows["stg.transactions"].append((
                    cid, text(x.get("id")), amount(x.get("value")), currency(x.get("value")),
                    payer.get("id"), payer.get("name"), payee.get("id"), payee.get("name"),
                ))
            for source, items in (("CONTRACT", c.get("milestones", [])),
                                  ("IMPLEMENTATION", impl.get("milestones", []))):
                for m in items:
                    rows["stg.milestones"].append((
                        cid, source, text(m.get("id")), m.get("title"), m.get("description"),
                        m.get("code"),
                        to_date(m.get("dueDate"), "milestones.dueDate"),
                        to_date(m.get("dateMet"), "milestones.dateMet"),
                        m.get("status"),
                    ))

        for p in r.get("parties") or []:
            ident = p.get("identifier") or {}
            rows["stg.parties"].append((
                rid, p.get("id"), p.get("name"),
                ident.get("scheme"), text(ident.get("id")), p.get("roles") or [],
            ))
    return rows


# Column lists exclude GENERATED and SERIAL columns; types guide COPY adaptation.
COPY_SPECS = {
    "stg.releases": (
        "release_id, ocid, release_date, tag, initiation_type, language, buyer_id, buyer_name, party_flag",
        ["text", "text", "timestamptz", "text[]", "text", "text", "text", "text", "text"]),
    "stg.planning": (
        "release_id, budget_id, budget_project_id, budget_amount, budget_currency, "
        "budget_description, budget_project",
        ["text", "text", "text", "numeric", "text", "text", "text"]),
    "stg.tender": (
        "release_id, tender_id, title, description, status, procurement_method, "
        "procurement_method_details, procurement_method_rationale, number_of_tenderers, "
        "tender_value_amount, tender_value_currency, tender_start_date, tender_end_date, "
        "award_criteria, award_criteria_details, has_enquiries, submission_method, "
        "submission_method_details",
        ["text", "text", "text", "text", "text", "text", "text", "text", "int4", "numeric", "text",
         "date", "date", "text", "text", "bool", "text[]", "text"]),
    "stg.awards": (
        "award_id, release_id, title, description, status, award_date, "
        "award_value_amount, award_value_currency",
        ["text", "text", "text", "text", "text", "date", "numeric", "text"]),
    "stg.award_suppliers": (
        "award_id, supplier_seq, supplier_id, supplier_name_raw",
        ["text", "int2", "text", "text"]),
    "stg.contracts": (
        "contract_id, release_id, award_id, title, description, status, contract_value_amount, "
        "contract_value_currency, date_signed, period_start_date, period_end_date, has_implementation",
        ["text", "text", "text", "text", "text", "text", "numeric", "text", "date", "date", "date", "bool"]),
    "stg.transactions": (
        "contract_id, transaction_id, transaction_value, transaction_currency, "
        "payer_id, payer_name, payee_id, payee_name",
        ["text", "text", "numeric", "text", "text", "text", "text", "text"]),
    "stg.milestones": (
        "contract_id, milestone_source, milestone_id, title, description, code, due_date, date_met, status",
        ["text", "text", "text", "text", "text", "text", "date", "date", "text"]),
    "stg.parties": (
        "release_id, party_id, party_name_raw, identifier_scheme, identifier_id, roles",
        ["text", "text", "text", "text", "text", "text[]"]),
}

LOAD_ORDER = [
    "stg.releases", "stg.planning", "stg.tender", "stg.awards", "stg.award_suppliers",
    "stg.contracts", "stg.transactions", "stg.milestones", "stg.parties",
]


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    if not os.path.exists(SOURCE):
        sys.exit(f"Source file not found: {SOURCE}")
    before = sha256(SOURCE)
    if before != EXPECTED_SHA256:
        sys.exit(f"Source checksum mismatch: {before} (expected {EXPECTED_SHA256}). "
                 "This loader is pinned to the 2021-05-03 snapshot; see data/README.md.")

    with open(SOURCE, encoding="utf-8") as fh:
        releases = json.load(fh, parse_float=Decimal)["releases"]
    rows = build_rows(releases)

    conninfo = dict(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5433"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "nocopo_db"),
    )
    with psycopg.connect(**conninfo) as conn:          # one transaction; commits on success
        with conn.cursor() as cur:
            cur.execute("TRUNCATE " + ", ".join(STAGING_TABLES) + " RESTART IDENTITY")
            for table in LOAD_ORDER:
                columns, types = COPY_SPECS[table]
                with cur.copy(f"COPY {table} ({columns}) FROM STDIN") as copy:
                    copy.set_types(types)
                    for row in rows[table]:
                        copy.write_row(row)
                print(f"  {table:<22} {len(rows[table]):>8,} rows")

    after = sha256(SOURCE)
    if after != before:
        sys.exit("Source file changed during load — investigate immediately.")
    print(f"Load committed to {conninfo['dbname']} on {conninfo['host']}:{conninfo['port']}. "
          "Source checksum unchanged.")


if __name__ == "__main__":
    main()
