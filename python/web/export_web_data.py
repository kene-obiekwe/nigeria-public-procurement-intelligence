"""
NOCOPO — Web Dashboard Data Export
==================================
Phase 13: Interactive Web Dashboard
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Write the static data files of the web dashboard (web/data/) from the validated
analytics.* views, so that the site needs no server and no database:

    dims.json             buyers (ID, label, name), methods, tender and contract statuses
    lifecycle.json        processes by buyer x highest stage (aggregated; counts only)
    budget.json           planning budget lines by buyer (aggregated; count and sum)
    competition.json      one row per OCID with a tender (M-C01, M-C02)
    awards.json           one row per eligible award (M-V01), with its M-S01 supplier and DQ-21 flag
    suppliers.json        one row per supplier with a usable supplier ID (M-S01)
    budget_award.json     one row per comparable OCID (budget-to-award), with the DQ-21 flag
    tender_duration.json  one row per eligible tender (M-E01)
    award_lag.json        one row per eligible OCID (M-E02)
    signature_lag.json    one row per eligible contract
    contracts.json        contracts by buyer x status x implementation data type (aggregated; counts only)
    entities.json         one row per procuring entity (vw_entity_benchmark, precomputed KPIs)
    registers.json        vw_metric_population and vw_dq_impact
    expected.json         the 177 figures of dashboard/reconciliation_expected_values.sql and the
                          Phase 10.1 DQ-21 sensitivity result sets, for the in-browser self-check
    manifest.json         source, database, role, row counts and SHA-256 of every file above

Encoding (docs/phase13_web_dashboard/web_design_note.md §2.1): fact files are
columnar ({column: [values]}); buyers and methods are indices into dims.json
(buyer -1 = the bare ID NG-BPP-, DQ-19); money is integer kobo (every value is
checked to be a whole number of kobo and below 2^53; totals are summed with
BigInt in the browser); register amounts larger than 2^53 kobo are exact
decimal strings. Rows are sorted by their source key, so a re-run on the same
database writes byte-identical files (only manifest.json carries a timestamp).

Access
------
Reads analytics.* only, in a read-only transaction. Every query (including the
reconciliation pack and the sensitivity result sets) is checked statically
before it runs: it may read only analytics.* views or its own CTEs and may not
contain DDL or DML. It works for the read-only role nocopo_bi:

    set PGUSER=nocopo_bi   (password through PGPASSWORD or pgpass)
    python python/web/export_web_data.py

or, from an owner login, with --role nocopo_bi (SET ROLE before reading).

Usage
-----
    python python/web/export_web_data.py
    python python/web/export_web_data.py --role nocopo_bi
    python python/web/export_web_data.py --static-check     # check the SQL only; no connection
"""

import argparse
import gzip
import hashlib
import importlib.util
import json
import os
import re
import sys
from datetime import datetime, timezone
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(ROOT, "web", "data")
PACK = os.path.join(ROOT, "dashboard", "reconciliation_expected_values.sql")
ANALYSIS_DIR = os.path.join(ROOT, "sql", "06_analysis")
SOURCE_SHA256 = "615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c"
BARE_BUYER = "NG-BPP-"
NOT_STATED = "(method not stated)"
MAX_SAFE = 2 ** 53 - 1

# Phase 10.1 DQ-21 sensitivity result sets checked by the web dashboard (script prefix, result set)
SENSITIVITY_RS = [("01", "RS6"), ("01", "RS6b"), ("03", "RS11"), ("03", "RS11a"), ("03", "RS11b"),
                  ("05", "RS7"), ("05", "RS7b")]

_runner = importlib.util.spec_from_file_location(
    "analysis_runner", os.path.join(ROOT, "python", "validation", "05_run_analysis_scripts.py"))
analysis_runner = importlib.util.module_from_spec(_runner)
_runner.loader.exec_module(analysis_runner)

# ---------------------------------------------------------------- queries (analytics.* only)
Q = {
    "buyers": "SELECT buyer_id, buyer_label, buyer_name FROM analytics.vw_dim_buyer ORDER BY buyer_id",
    "methods": "SELECT procurement_method FROM analytics.vw_dim_procurement_method ORDER BY procurement_method",
    "lifecycle": """SELECT buyer_id, buyer_id_flag, highest_stage_rank, count(*)
                    FROM analytics.vw_lifecycle_stage GROUP BY 1, 2, 3 ORDER BY 1, 3""",
    "budget": """SELECT buyer_id, count(*), sum(budget_amount), bool_and(budget_amount * 100 = trunc(budget_amount * 100))
                 FROM analytics.vw_budget_eligible GROUP BY 1 ORDER BY 1""",
    "competition": """SELECT buyer_id, buyer_id_flag, procurement_method_details, tender_status, number_of_tenderers,
                             in_primary_population, is_single_bidder
                      FROM analytics.vw_competition_eligible ORDER BY ocid""",
    "awards": """WITH flag AS MATERIALIZED (
                     SELECT award_id, dropped_decimal_test, sibling_lot_test FROM analytics.vw_award_scale_flag),
                 sup AS MATERIALIZED (
                     SELECT award_id, supplier_id, award_value_amount AS sup_value, buyer_id AS sup_buyer,
                            procurement_method_details AS sup_method
                     FROM analytics.vw_supplier_award_eligible)
                 SELECT a.award_id, a.buyer_id, a.buyer_id_flag, a.procurement_method_details, a.award_value_amount,
                        s.supplier_id, s.sup_value, s.sup_buyer, s.sup_method,
                        f.award_id IS NOT NULL, coalesce(f.dropped_decimal_test, false), coalesce(f.sibling_lot_test, false)
                 FROM analytics.vw_award_value_eligible a
                 LEFT JOIN sup s ON s.award_id = a.award_id
                 LEFT JOIN flag f ON f.award_id = a.award_id
                 ORDER BY a.award_id""",
    "suppliers": """SELECT supplier_id, min(supplier_name), max(supplier_name), max(name_variant_count),
                           count(*), max(distinct_supplier_count)
                    FROM analytics.vw_supplier_award_eligible GROUP BY 1 ORDER BY 1""",
    "budget_award": """WITH flag AS MATERIALIZED (SELECT award_id FROM analytics.vw_award_scale_flag)
                       SELECT b.buyer_id, b.buyer_id_flag, b.procurement_method_details, b.budget_amount,
                              b.award_value_amount, b.variance_amount, b.award_to_budget_ratio,
                              EXISTS (SELECT 1 FROM flag f WHERE f.award_id = b.award_id)
                       FROM analytics.vw_budget_award_comparison b ORDER BY b.ocid""",
    "tender_duration": """SELECT buyer_id, buyer_id_flag, procurement_method_details,
                                 extract(year FROM tender_start_date)::int, tender_duration_days
                          FROM analytics.vw_tender_duration_eligible ORDER BY ocid""",
    "award_lag": """SELECT buyer_id, buyer_id_flag, procurement_method_details,
                           extract(year FROM award_date)::int, award_lag_days
                    FROM analytics.vw_award_lag_eligible ORDER BY ocid""",
    "signature_lag": """SELECT buyer_id, buyer_id_flag, signature_lag_days
                        FROM analytics.vw_signature_lag_eligible ORDER BY contract_id, ocid""",
    "contracts": """SELECT buyer_id, buyer_id_flag, contract_status,
                           CASE WHEN transaction_count > 0 AND implementation_milestone_count > 0 THEN 1
                                WHEN implementation_milestone_count > 0 THEN 2
                                WHEN transaction_count > 0 THEN 3 ELSE 4 END,
                           has_implementation, count(*)
                    FROM analytics.vw_contract_implementation_coverage GROUP BY 1, 2, 3, 4, 5 ORDER BY 1, 3, 4, 5""",
    "entities": "SELECT * FROM analytics.vw_entity_benchmark ORDER BY buyer_id",
    "metric_population": "SELECT * FROM analytics.vw_metric_population ORDER BY metric_id",
    "dq_impact": "SELECT * FROM analytics.vw_dq_impact ORDER BY metric_order, metric_id, dq_ref",
    "view_counts": """SELECT 'vw_dim_buyer', count(*) FROM analytics.vw_dim_buyer
        UNION ALL SELECT 'vw_dim_procurement_method', count(*) FROM analytics.vw_dim_procurement_method
        UNION ALL SELECT 'vw_lifecycle_stage', count(*) FROM analytics.vw_lifecycle_stage
        UNION ALL SELECT 'vw_budget_eligible', count(*) FROM analytics.vw_budget_eligible
        UNION ALL SELECT 'vw_competition_eligible', count(*) FROM analytics.vw_competition_eligible
        UNION ALL SELECT 'vw_award_value_eligible', count(*) FROM analytics.vw_award_value_eligible
        UNION ALL SELECT 'vw_supplier_award_eligible', count(*) FROM analytics.vw_supplier_award_eligible
        UNION ALL SELECT 'vw_award_scale_flag', count(*) FROM analytics.vw_award_scale_flag
        UNION ALL SELECT 'vw_budget_award_comparison', count(*) FROM analytics.vw_budget_award_comparison
        UNION ALL SELECT 'vw_tender_duration_eligible', count(*) FROM analytics.vw_tender_duration_eligible
        UNION ALL SELECT 'vw_award_lag_eligible', count(*) FROM analytics.vw_award_lag_eligible
        UNION ALL SELECT 'vw_signature_lag_eligible', count(*) FROM analytics.vw_signature_lag_eligible
        UNION ALL SELECT 'vw_contract_implementation_coverage', count(*) FROM analytics.vw_contract_implementation_coverage
        UNION ALL SELECT 'vw_entity_benchmark', count(*) FROM analytics.vw_entity_benchmark
        UNION ALL SELECT 'vw_metric_population', count(*) FROM analytics.vw_metric_population
        UNION ALL SELECT 'vw_dq_impact', count(*) FROM analytics.vw_dq_impact""",
}

# ---------------------------------------------------------------- static check
OTHER_SCHEMA = re.compile(r"\b(stg|core|public|pg_catalog|pg_temp|information_schema)\s*\.", re.IGNORECASE)
DDL_DML = re.compile(r"\b(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|TRUNCATE|GRANT|REVOKE|COPY|CALL|DO)\b", re.IGNORECASE)
SOURCE = re.compile(r"\b(?:FROM|JOIN)\s+(?!\()([A-Za-z_][\w.]*)", re.IGNORECASE)
CTE = re.compile(r"\b([A-Za-z_]\w*)\s*(?:\([^()]*\))?\s+AS\s+(?:NOT\s+)?(?:MATERIALIZED\s+)?\(", re.IGNORECASE)
SET_RETURNING = {"generate_series", "unnest"}


def static_problems(name, sql):
    """Problems that would let a query read outside analytics.* or change anything."""
    code = analysis_runner.strip_comments(sql)
    code = re.sub(r"'(?:[^']|'')*'", "''", code)          # ignore string literals
    code = re.sub(r"\b(EXTRACT|SUBSTRING|TRIM)\s*\(\s*\w+\s+FROM\b", r"\1(", code, flags=re.IGNORECASE)
    problems = [f"{name}: names another schema: {m.group(0)}" for m in OTHER_SCHEMA.finditer(code)]
    problems += [f"{name}: DDL/DML keyword: {m.group(0)}" for m in DDL_DML.finditer(code)]
    ctes = {m.group(1).lower() for m in CTE.finditer(code)}
    for m in SOURCE.finditer(code):
        target = m.group(1).lower()
        if target.startswith("analytics.") or target in ctes or target in SET_RETURNING:
            continue
        problems.append(f"{name}: reads '{m.group(1)}', which is neither analytics.* nor a CTE of the query")
    return problems


def sensitivity_queries():
    out = {}
    for prefix, rs in SENSITIVITY_RS:
        path = next(os.path.join(ANALYSIS_DIR, f) for f in sorted(os.listdir(ANALYSIS_DIR)) if f.startswith(prefix))
        with open(path, encoding="utf-8") as fh:
            _, sections = analysis_runner.split_script(fh.read())
        sql = next(s for i, _, s in sections if i == rs)
        out[f"{prefix}/{rs}"] = sql.rstrip().rstrip(";")
    return out


def all_queries():
    with open(PACK, encoding="utf-8") as fh:
        pack = fh.read().rstrip().rstrip(";")
    return {**Q, "reconciliation_pack": pack, **{f"sensitivity {k}": v for k, v in sensitivity_queries().items()}}


# ---------------------------------------------------------------- encoding helpers
def kobo(value, what):
    k = Decimal(value) * 100
    if k != k.to_integral_value():
        raise ValueError(f"{what}: {value} is not a whole number of kobo")
    k = int(k)
    if abs(k) > MAX_SAFE:
        raise ValueError(f"{what}: {value} NGN exceeds 2^53 kobo; it must ship as a string")
    return k


def plain(v):
    """JSON-safe value: Decimal -> exact string, everything else as is."""
    if isinstance(v, Decimal):
        text = format(v, "f")
        return text.rstrip("0").rstrip(".") if "." in text else text
    if isinstance(v, (list, tuple)):
        return [plain(x) for x in v]
    return v


class Encoder:
    def __init__(self, buyers, methods):
        self.bidx = {b[0]: i for i, b in enumerate(buyers)}
        self.midx = {m: i for i, m in enumerate(methods)}

    def buyer(self, buyer_id, flag):
        if buyer_id in self.bidx:
            if flag is not None:
                raise ValueError(f"buyer {buyer_id} is in vw_dim_buyer but carries buyer_id_flag {flag}")
            return self.bidx[buyer_id]
        if buyer_id == BARE_BUYER and flag == "INCOMPLETE":
            return -1
        raise ValueError(f"buyer {buyer_id!r} (flag {flag!r}) is neither in vw_dim_buyer nor the bare ID")

    def method(self, m):
        return self.midx[m if m is not None else NOT_STATED]


def dumps(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


# ---------------------------------------------------------------- export
def export(conn):
    q = lambda name: conn.execute(Q[name]).fetchall()
    files, rows_of = {}, {}

    buyers = q("buyers")
    methods = [m for (m,) in q("methods")]
    if NOT_STATED not in methods:
        raise ValueError(f"'{NOT_STATED}' missing from vw_dim_procurement_method")
    enc = Encoder(buyers, methods)

    comp = q("competition")
    tender_statuses = sorted({r[3] for r in comp if r[3] is not None})
    contracts = q("contracts")
    contract_statuses = sorted({r[2] for r in contracts if r[2] is not None})
    files["dims"] = {"buyers": [list(b) for b in buyers], "methods": methods,
                     "bare_buyer": BARE_BUYER, "tender_statuses": tender_statuses,
                     "contract_statuses": contract_statuses}
    rows_of["dims"] = len(buyers) + len(methods)

    lc = q("lifecycle")
    files["lifecycle"] = {"b": [enc.buyer(r[0], r[1]) for r in lc], "k": [r[2] for r in lc], "n": [r[3] for r in lc]}
    rows_of["lifecycle"] = sum(r[3] for r in lc)

    bud = q("budget")
    if not all(r[3] for r in bud):
        raise ValueError("a budget line is not a whole number of kobo")
    files["budget"] = {"b": [enc.buyer(r[0], None) for r in bud], "n": [r[1] for r in bud],
                       "v": [kobo(r[2], f"budget total of {r[0]}") for r in bud]}
    rows_of["budget"] = sum(r[1] for r in bud)

    sidx = {}
    sups = q("suppliers")
    for sid, name_min, name_max, variants, n, dsc in sups:
        if name_min != name_max or dsc != 1:
            raise ValueError(f"supplier {sid}: several names or several suppliers per award; the encoding assumes neither")
        sidx[sid] = len(sidx)
    files["suppliers"] = {"id": [r[0] for r in sups], "name": [r[1] for r in sups], "variants": [r[3] for r in sups]}
    rows_of["suppliers"] = len(sups)

    status_idx = {s: i for i, s in enumerate(tender_statuses)}
    files["competition"] = {
        "b": [enc.buyer(r[0], r[1]) for r in comp], "m": [enc.method(r[2]) for r in comp],
        "s": [status_idx.get(r[3], -1) for r in comp], "t": [r[4] for r in comp],
        "p": [int(r[5]) for r in comp], "sb": [int(r[6]) for r in comp]}
    rows_of["competition"] = len(comp)

    aw = q("awards")
    a_s, a_f = [], []
    for (award_id, buyer, flag, method, value, sid, sval, sbuyer, smethod, flagged, dropped, sibling) in aw:
        if sid is not None and (sval != value or sbuyer != buyer or smethod != method):
            raise ValueError(f"award {award_id}: M-S01 row differs from its M-V01 row")
        a_s.append(sidx[sid] if sid is not None else -1)
        a_f.append((1 if dropped else 0) | (2 if sibling else 0) if flagged else 0)
        if flagged and not (dropped or sibling):
            raise ValueError(f"award {award_id}: flagged without a test")
    files["awards"] = {"b": [enc.buyer(r[1], r[2]) for r in aw], "m": [enc.method(r[3]) for r in aw],
                       "v": [kobo(r[4], f"award {r[0]}") for r in aw], "s": a_s, "f": a_f}
    rows_of["awards"] = len(aw)

    bva = q("budget_award")
    for r in bva:
        if r[5] != r[4] - r[3]:
            raise ValueError("variance_amount is not award minus budget")
    files["budget_award"] = {
        "b": [enc.buyer(r[0], r[1]) for r in bva], "m": [enc.method(r[2]) for r in bva],
        "bud": [kobo(r[3], "budget") for r in bva], "aw": [kobo(r[4], "award") for r in bva],
        "r": [float(r[6]) for r in bva], "f": [int(r[7]) for r in bva]}
    if any(Decimal(str(x)) != r[6] for x, r in zip(files["budget_award"]["r"], bva)):
        raise ValueError("a ratio does not survive the float round trip")
    rows_of["budget_award"] = len(bva)

    for name in ("tender_duration", "award_lag"):
        rs = q(name)
        files[name] = {"b": [enc.buyer(r[0], r[1]) for r in rs], "m": [enc.method(r[2]) for r in rs],
                       "y": [r[3] for r in rs], "d": [r[4] for r in rs]}
        rows_of[name] = len(rs)
    sl = q("signature_lag")
    files["signature_lag"] = {"b": [enc.buyer(r[0], r[1]) for r in sl], "d": [r[2] for r in sl]}
    rows_of["signature_lag"] = len(sl)

    cstat_idx = {s: i for i, s in enumerate(contract_statuses)}
    files["contracts"] = {"b": [enc.buyer(r[0], r[1]) for r in contracts], "s": [cstat_idx.get(r[2], -1) for r in contracts],
                          "t": [r[3] for r in contracts], "h": [int(r[4]) for r in contracts],
                          "n": [r[5] for r in contracts]}
    rows_of["contracts"] = sum(r[5] for r in contracts)

    cur = conn.execute(Q["entities"])
    cols = [d.name for d in cur.description]
    money = {"planned_budget_total", "award_value_total", "median_award_value"}
    ent = {c: [] for c in cols}
    for row in cur.fetchall():
        for c, v in zip(cols, row):
            if c in money:
                v = None if v is None else kobo(v, f"{c} of {row[0]}")
            elif isinstance(v, Decimal):
                v = float(v)
            ent[c].append(v)
    ent["b"] = [enc.buyer(b, None) for b in ent["buyer_id"]]
    del ent["buyer_id"], ent["buyer_name"]           # in dims.json
    files["entities"] = ent
    rows_of["entities"] = len(ent["b"])

    def table(name):
        cur = conn.execute(Q[name])
        return {"cols": [d.name for d in cur.description], "rows": [plain(list(r)) for r in cur.fetchall()]}
    files["registers"] = {"metric_population": table("metric_population"), "dq_impact": table("dq_impact")}
    rows_of["registers"] = len(files["registers"]["metric_population"]["rows"]) + len(files["registers"]["dq_impact"]["rows"])

    # expected values: the 177-figure pack and the DQ-21 sensitivity result sets
    queries = all_queries()
    cur = conn.execute(queries["reconciliation_pack"])
    pack = [dict(zip(["id", "page", "figure", "measure", "slice", "value", "unit", "n"], plain(list(r))))
            for r in cur.fetchall()]
    sens = {}
    for key, sql in sensitivity_queries().items():
        cur = conn.execute(sql)
        sens[key] = {"cols": [d.name for d in cur.description], "rows": [plain(list(r)) for r in cur.fetchall()]}
    files["expected"] = {"pack": pack, "sensitivity": sens}
    rows_of["expected"] = len(pack)

    counts = dict(conn.execute(Q["view_counts"]).fetchall())
    return files, rows_of, counts


def main():
    parser = argparse.ArgumentParser(description="Export the web dashboard data from analytics.* views.")
    parser.add_argument("--role", help="SET ROLE to this role before reading (e.g. nocopo_bi)")
    parser.add_argument("--out", default=OUT_DIR)
    parser.add_argument("--static-check", action="store_true", help="check the SQL only and exit")
    args = parser.parse_args()

    problems = [p for name, sql in all_queries().items() for p in static_problems(name, sql)]
    if problems:
        print("Static check FAILED:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print(f"Static check: {len(all_queries())} queries read analytics.* only and contain no DDL/DML.")
    if args.static_check:
        return

    conninfo = dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5433"),
                    user=os.environ.get("PGUSER", "postgres"), dbname=os.environ.get("PGDATABASE", "nocopo_db"))
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        if args.role:
            conn.execute(psycopg.sql.SQL("SET ROLE {}").format(psycopg.sql.Identifier(args.role)))
        who = conn.execute("SELECT current_user").fetchone()[0]
        read_only = conn.execute("SHOW transaction_read_only").fetchone()[0]
        server = conn.execute("SHOW server_version").fetchone()[0]
        files, rows_of, counts = export(conn)
        conn.rollback()

    os.makedirs(args.out, exist_ok=True)
    manifest_files, raw_total, gz_total = {}, 0, 0
    for name, obj in files.items():
        data = dumps(obj)
        with open(os.path.join(args.out, f"{name}.json"), "wb") as fh:
            fh.write(data)
        gz = len(gzip.compress(data, 9, mtime=0))
        raw_total, gz_total = raw_total + len(data), gz_total + gz
        manifest_files[f"{name}.json"] = {"rows": rows_of[name], "bytes": len(data), "gzip_bytes": gz,
                                          "sha256": hashlib.sha256(data).hexdigest()}
    manifest = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "generator": "python/web/export_web_data.py",
        "source_sha256": SOURCE_SHA256,
        "database": conninfo["dbname"], "server_version": server, "role": who, "read_only": read_only,
        "view_row_counts": counts,
        "files": manifest_files,
        "total_bytes": raw_total, "total_gzip_bytes": gz_total,
    }
    with open(os.path.join(args.out, "manifest.json"), "wb") as fh:
        fh.write(json.dumps(manifest, ensure_ascii=False, indent=1).encode("utf-8") + b"\n")

    print(f"Read as role {who} (transaction_read_only = {read_only}), PostgreSQL {server}.")
    for name, m in manifest_files.items():
        print(f"  {name:<22}{m['rows']:>9,} rows {m['bytes'] / 1024:>9.1f} KB {m['gzip_bytes'] / 1024:>8.1f} KB gzip")
    print(f"  {'total':<22}{'':>14} {raw_total / 1024:>9.1f} KB {gz_total / 1024:>8.1f} KB gzip")
    print(f"Wrote {len(files) + 1} files to {os.path.relpath(args.out, ROOT)}")


if __name__ == "__main__":
    main()
