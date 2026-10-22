"""
NOCOPO — Web Dashboard Data Check
=================================
Phase 13: Interactive Web Dashboard
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Prove that the committed web data (web/data/*.json) reproduces the published
figures, and write docs/phase13_web_dashboard/web_reconciliation_results.md:

1. Manifest. Every file's SHA-256 and size match manifest.json; the row counts
   recounted from the JSON match the manifest and the live analytics.* views.
2. Reconciliation. dashboard/reconciliation_expected_values.sql is re-run
   (read-only) and each of its 177 figures is recomputed from the JSON alone,
   with the slice named in the pack, by Python functions that mirror the DAX
   measures in dashboard/README.md §5. Tolerance as in the reconciliation log:
   counts, days and bands identical; NGN to the whole naira; ratios and shares
   to four decimals; the index to one decimal. expected.json (read by the
   in-browser self-check) must equal the live values.
3. DQ-21 sensitivity. The Phase 10.1 result sets 01/RS6, 01/RS6b, 03/RS11,
   03/RS11a, 03/RS11b, 05/RS7 and 05/RS7b are re-run and recomputed from the
   JSON, cell by cell, at the precision each result set rounds to.
4. In-browser self-check. web/check.html runs the site's JavaScript functions
   over the same JSON against expected.json; its result is recorded with
   --browser-result and kept while expected.json is unchanged.
5. Wording. The site's own text (web/**/*.html, *.js, *.css; not data/ or
   vendor/) is scanned for the words in dashboard/README.md §7.3, except inside
   the mandatory caveat sentences of §8.

This is an independent implementation of the measures: it shares no code with
the site's JavaScript, so a defect in either shows up as a disagreement.

Access
------
Reads analytics.* only (the pack and the result sets are checked statically by
export_web_data.py), in a read-only transaction; nocopo_bi is sufficient.
Use PGUSER=nocopo_bi or --role nocopo_bi as for the export.

Usage
-----
    python python/web/check_web_data.py
    python python/web/check_web_data.py --role nocopo_bi
    python python/web/check_web_data.py --browser-result "177/177 PASS; 77/77 sensitivity PASS; <browser>, <date>"

Exit code 1 if anything fails.
"""

import argparse
import glob
import hashlib
import importlib.util
import json
import os
import re
import sys
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal, getcontext

import psycopg

getcontext().prec = 50
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA = os.path.join(ROOT, "web", "data")
OUTPUT_REL = os.path.join("docs", "phase13_web_dashboard", "web_reconciliation_results.md")
README = os.path.join(ROOT, "dashboard", "README.md")

_spec = importlib.util.spec_from_file_location("export_web_data", os.path.join(ROOT, "python", "web", "export_web_data.py"))
export_web_data = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(export_web_data)

D0 = Decimal(0)
D100 = Decimal(100)


# ================================================================ loading
class Web:
    """The web data, decoded. Money stays integer kobo; buyers and methods stay indices."""

    def __init__(self, data_dir):
        load = lambda n: json.load(open(os.path.join(data_dir, f"{n}.json"), encoding="utf-8"))
        self.dims = load("dims")
        for name in ("lifecycle", "budget", "competition", "awards", "suppliers", "budget_award",
                     "tender_duration", "award_lag", "signature_lag", "contracts", "entities", "registers"):
            setattr(self, name, load(name))
        self.buyer_ids = [b[0] for b in self.dims["buyers"]]
        self.buyer_names = [b[2] for b in self.dims["buyers"]]
        self.bidx = {b: i for i, b in enumerate(self.buyer_ids)}
        self.midx = {m: i for i, m in enumerate(self.dims["methods"])}
        self.tsidx = {s: i for i, s in enumerate(self.dims["tender_statuses"])}
        self.csidx = {s: i for i, s in enumerate(self.dims["contract_statuses"])}

    def buyer_id(self, b):
        return self.dims["bare_buyer"] if b < 0 else self.buyer_ids[b]

    def rows(self, table, f):
        """Row indices of a columnar table that pass filter f (only the fields the table carries apply)."""
        t = getattr(self, table)
        n = len(next(iter(t.values())))
        keep = range(n)
        if "buyer" in f and "b" in t:
            b = self.bidx.get(f["buyer"], -2)
            keep = [i for i in keep if t["b"][i] == b]
        if "method" in f and "m" in t:
            m = self.midx[f["method"]]
            keep = [i for i in keep if t["m"][i] == m]
        if "tender_status" in f and table == "competition":
            s = self.tsidx[f["tender_status"]]
            keep = [i for i in keep if t["s"][i] == s]
        if "contract_status" in f and table == "contracts":
            s = self.csidx[f["contract_status"]]
            keep = [i for i in keep if t["s"][i] == s]
        if "tender_start_year" in f and table == "tender_duration":
            keep = [i for i in keep if t["y"][i] == f["tender_start_year"]]
        if "award_year" in f and table == "award_lag":
            keep = [i for i in keep if t["y"][i] == f["award_year"]]
        if f.get("dq21") == "exclude" and table in ("awards", "budget_award"):
            keep = [i for i in keep if not t["f"][i]]
        return list(keep)


# ================================================================ measure helpers (DAX equivalents)
def naira(kobo):
    return Decimal(kobo) / D100


def percentile_inc(values, p):
    """DAX PERCENTILE.INC / MEDIAN = SQL percentile_cont: linear interpolation between closest ranks."""
    v = sorted(Decimal(str(x)) for x in values)
    if not v:
        return None
    pos = Decimal(str(p)) * (len(v) - 1)
    lo = int(pos)
    frac = pos - lo
    return v[lo] if lo + 1 >= len(v) else v[lo] + (v[lo + 1] - v[lo]) * frac


def divide(a, b):
    return None if not b else Decimal(a) / Decimal(b)


def topn_sum(values, n):
    """Sum of the n largest values; like DAX TOPN, every value tied with the n-th is included."""
    v = sorted(values, reverse=True)
    if len(v) <= n:
        return sum(v)
    cut = v[n - 1]
    return sum(x for x in v if x >= cut)


def by_key(keys, vals):
    out = {}
    for k, x in zip(keys, vals):
        out[k] = out.get(k, 0) + x
    return out


def band_tenderers(t):
    for b, hi in enumerate((1, 2, 5, 10, 20, 50, 100), start=1):
        if t <= hi:
            return b
    return 8


def band_ratio(r):
    if r < 0.5:
        return 1
    if r < 0.9:
        return 2
    if r <= 1.1:
        return 3
    if r <= 1.5:
        return 4
    return 5 if r <= 10 else 6


def band_days(d):
    for b, hi in enumerate((7, 30, 90, 180, 365), start=1):
        if d <= hi:
            return b
    return 6


# ================================================================ measures
def col(w, table, name, idx):
    c = getattr(w, table)[name]
    return [c[i] for i in idx]


def m_awards(w, f):
    return w.rows("awards", f)


def m_supplier_rows(w, f):
    return [i for i in w.rows("awards", f) if w.awards["s"][i] >= 0]


def supplier_values(w, f):
    idx = m_supplier_rows(w, f)
    return by_key(col(w, "awards", "s", idx), col(w, "awards", "v", idx))


def entity_values(w, f):
    """Entity award totals keyed by buyer index, from vw_entity_benchmark (blank -> 0, as in the pack)."""
    e = w.entities
    keep = [i for i, b in enumerate(e["b"]) if "buyer" not in f or w.buyer_ids[b] == f["buyer"]]
    return {e["b"][i]: (e["award_value_total"][i] or 0) for i in keep}


def comp_rows(w, f, primary=None):
    idx = w.rows("competition", f)
    return idx if primary is None else [i for i in idx if w.competition["p"][i] == primary]


def lifecycle(w, f):
    idx = w.rows("lifecycle", f)
    return [(w.lifecycle["k"][i], w.lifecycle["n"][i]) for i in idx]


def contracts(w, f):
    idx = w.rows("contracts", f)
    c = w.contracts
    return [(c["t"][i], c["h"][i], c["n"][i]) for i in idx]


def reached(w, f, k):
    return sum(n for s, n in lifecycle(w, f) if s >= k)


def register(w, metric_id):
    t = w.registers["metric_population"]
    row = next(r for r in t["rows"] if r[0] == metric_id)
    return dict(zip(t["cols"], row))


def dq(w, metric_id, dq_ref):
    t = w.registers["dq_impact"]
    row = next(r for r in t["rows"] if r[1] == metric_id and r[4] == dq_ref)
    return dict(zip(t["cols"], row))


def entity_kpi(w, f, column):
    e = w.entities
    i = e["b"].index(w.bidx[f["buyer"]])
    v = e[column][i]
    return None if v is None else (naira(v) if column == "median_award_value" else Decimal(str(v)))


def median_entity(w, kpi, n_col, min_n):
    e = w.entities
    return percentile_inc([e[kpi][i] for i in range(len(e["b"])) if (e[n_col][i] or 0) >= min_n and e[kpi][i] is not None], 0.5)


def single_bidder_rate(w, f, primary):
    idx = comp_rows(w, f, 1 if primary else None)
    return divide(sum(w.competition["sb"][i] for i in idx), len(idx))


def topn_supplier_share(w, f, n):
    v = supplier_values(w, f)
    return divide(topn_sum(list(v.values()), n), sum(v.values()))


def hhi(w, f):
    v = supplier_values(w, f)
    tot = Decimal(sum(v.values()))
    return sum((Decimal(x) / tot) ** 2 for x in v.values()) * 10000


def award_value(w, f):
    return naira(sum(col(w, "awards", "v", m_awards(w, f))))


def supplier_value(w, f):
    return naira(sum(col(w, "awards", "v", m_supplier_rows(w, f))))


MEASURES = {
    "[Processes (n)]": lambda w, f, p: Decimal(sum(n for _, n in lifecycle(w, f))),
    "[Planning-Only Share]": lambda w, f, p: divide(sum(n for s, n in lifecycle(w, f) if s == 1), sum(n for _, n in lifecycle(w, f))),
    "[OCIDs Reaching Stage]": lambda w, f, p: Decimal(reached(w, f, p["stage"])),
    "[Stage Conversion Rate]": lambda w, f, p: divide(reached(w, f, p["stage"]), reached(w, f, p["stage"] - 1)),
    "[Planned Budget (NGN)]": lambda w, f, p: naira(sum(col(w, "budget", "v", w.rows("budget", f)))),
    "[Award Value (NGN)]": lambda w, f, p: award_value(w, f),
    "[Median Award Value (NGN)]": lambda w, f, p: percentile_inc([naira(x) for x in col(w, "awards", "v", m_awards(w, f))], 0.5),
    "[M-S01 Eligible Awards]": lambda w, f, p: Decimal(len(m_supplier_rows(w, f))),
    "[Suppliers (n)]": lambda w, f, p: Decimal(len(supplier_values(w, f))),
    "[Supplier Value (NGN)]": lambda w, f, p: supplier_value(w, f),
    "[Top N Supplier Share]": lambda w, f, p: topn_supplier_share(w, f, p["n"]),
    "[Supplier HHI]": lambda w, f, p: hhi(w, f),
    "[Suppliers With One Award]": lambda w, f, p: Decimal(sum(1 for c in by_key(
        col(w, "awards", "s", m_supplier_rows(w, f)), [1] * len(m_supplier_rows(w, f))).values() if c == 1)),
    "[M-S01 Excluded Awards]": lambda w, f, p: Decimal(len(m_awards(w, f)) - len(m_supplier_rows(w, f))),
    "[M-S01 Excluded Value (NGN)]": lambda w, f, p: award_value(w, f) - supplier_value(w, f),
    "[M-S01 Excluded Value Share]": lambda w, f, p: divide(award_value(w, f) - supplier_value(w, f), award_value(w, f)),
    "[M-S01 Excluded Awards (DQ view)]": lambda w, f, p: Decimal(dq(w, "M-S01", "DQ-14")["records_with_issue"]),
    "[M-S01 Excluded Value (DQ view)]": lambda w, f, p: Decimal(dq(w, "M-S01", "DQ-14")["affected_value_ngn"]),
    "[Competition n (primary)]": lambda w, f, p: Decimal(len(comp_rows(w, f, 1))),
    "[Competition n (sensitivity)]": lambda w, f, p: Decimal(len(comp_rows(w, f))),
    "[Median Tenderers (primary)]": lambda w, f, p: percentile_inc(col(w, "competition", "t", comp_rows(w, f, 1)), 0.5),
    "[Median Tenderers (sensitivity)]": lambda w, f, p: percentile_inc(col(w, "competition", "t", comp_rows(w, f)), 0.5),
    "[Single-Bidder Rate (primary)]": lambda w, f, p: single_bidder_rate(w, f, True),
    "[Single-Bidder Rate (sensitivity)]": lambda w, f, p: single_bidder_rate(w, f, False),
    "[Tenders (n)] by [Participation Band]": lambda w, f, p: Decimal(sum(
        1 for i in comp_rows(w, f, p["population"]) if band_tenderers(w.competition["t"][i]) == p["band"])),
    "[Comparable OCIDs]": lambda w, f, p: Decimal(len(w.rows("budget_award", f))),
    "[Budget of Comparable OCIDs (NGN)]": lambda w, f, p: naira(sum(col(w, "budget_award", "bud", w.rows("budget_award", f)))),
    "[Award of Comparable OCIDs (NGN)]": lambda w, f, p: naira(sum(col(w, "budget_award", "aw", w.rows("budget_award", f)))),
    "[Net Variance (NGN)]": lambda w, f, p: naira(sum(w.budget_award["aw"][i] - w.budget_award["bud"][i] for i in w.rows("budget_award", f))),
    "[Aggregate Award-to-Budget Ratio]": lambda w, f, p: divide(sum(col(w, "budget_award", "aw", w.rows("budget_award", f))),
                                                                 sum(col(w, "budget_award", "bud", w.rows("budget_award", f)))),
    "[Median Award-to-Budget Ratio]": lambda w, f, p: percentile_inc(col(w, "budget_award", "r", w.rows("budget_award", f)), 0.5),
    "[Share Within 10% of Budget]": lambda w, f, p: divide(sum(1 for r in col(w, "budget_award", "r", w.rows("budget_award", f))
                                                              if 0.9 <= r <= 1.1), len(w.rows("budget_award", f))),
    "[OCIDs With Budget Under 100k]": lambda w, f, p: Decimal(sum(1 for x in col(w, "budget_award", "bud", w.rows("budget_award", f))
                                                                 if x < 100000 * 100)),
    "[Comparable OCIDs] by [Ratio Band]": lambda w, f, p: Decimal(sum(
        1 for r in col(w, "budget_award", "r", w.rows("budget_award", f)) if band_ratio(r) == p["band"])),
    "[Tender Duration n]": lambda w, f, p: Decimal(len(w.rows("tender_duration", f))),
    "[Award Lag n]": lambda w, f, p: Decimal(len(w.rows("award_lag", f))),
    "[Signature Lag n]": lambda w, f, p: Decimal(len(w.rows("signature_lag", f))),
    "[Median Tender Duration (days)]": lambda w, f, p: percentile_inc(col(w, "tender_duration", "d", w.rows("tender_duration", f)), 0.5),
    "[Median Award Lag (days)]": lambda w, f, p: percentile_inc(col(w, "award_lag", "d", w.rows("award_lag", f)), 0.5),
    "[Median Signature Lag (days)]": lambda w, f, p: percentile_inc(col(w, "signature_lag", "d", w.rows("signature_lag", f)), 0.5),
    "[P90 Tender Duration (days)]": lambda w, f, p: percentile_inc(col(w, "tender_duration", "d", w.rows("tender_duration", f)), 0.9),
    "[P90 Award Lag (days)]": lambda w, f, p: percentile_inc(col(w, "award_lag", "d", w.rows("award_lag", f)), 0.9),
    "[P90 Signature Lag (days)]": lambda w, f, p: percentile_inc(col(w, "signature_lag", "d", w.rows("signature_lag", f)), 0.9),
    "[Award Lag Over 1 Year Share]": lambda w, f, p: divide(sum(1 for d in col(w, "award_lag", "d", w.rows("award_lag", f)) if d > 365),
                                                           len(w.rows("award_lag", f))),
    "[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]": lambda w, f, p: Decimal(sum(
        1 for d in col(w, p["timing_table"], "d", w.rows(p["timing_table"], f)) if band_days(d) == p["band"])),
    "[Coverage M-E01]": lambda w, f, p: divide(register(w, "M-E01")["eligible_count"], register(w, "M-E01")["candidate_count"]),
    "[Coverage M-E02]": lambda w, f, p: divide(register(w, "M-E02")["eligible_count"], register(w, "M-E02")["candidate_count"]),
    "[Coverage Signature Lag]": lambda w, f, p: divide(register(w, "P5-SIG")["eligible_count"], register(w, "P5-SIG")["candidate_count"]),
    "[Entities (n)]": lambda w, f, p: Decimal(len(entity_values(w, f))),
    "[Entity Processes]": lambda w, f, p: Decimal(sum(w.entities["process_count"])),
    "[Entity Planned Budget (NGN)]": lambda w, f, p: naira(sum(x or 0 for x in w.entities["planned_budget_total"])),
    "[Entity Award Value (NGN)]": lambda w, f, p: naira(sum(entity_values(w, f).values())),
    "[Top N Entity Share]": lambda w, f, p: divide(topn_sum(list(entity_values(w, f).values()), p["n"]), sum(entity_values(w, f).values())),
    "[Median Entity Single-Bidder Rate]": lambda w, f, p: median_entity(w, "single_bidder_rate", "competition_n", p["min_n"]),
    "[Median Entity Top-Supplier Share]": lambda w, f, p: median_entity(w, "top_supplier_value_share", "award_n", p["min_n"]),
    "[Median Entity Implementation Coverage]": lambda w, f, p: median_entity(w, "implementation_coverage_rate", "contract_n", p["min_n"]),
    "[Entity Single-Bidder Rate]": lambda w, f, p: entity_kpi(w, f, "single_bidder_rate"),
    "[Entity Top-Supplier Share]": lambda w, f, p: entity_kpi(w, f, "top_supplier_value_share"),
    "[Entity Implementation Coverage]": lambda w, f, p: entity_kpi(w, f, "implementation_coverage_rate"),
    "[Entity Tender Reach Rate]": lambda w, f, p: entity_kpi(w, f, "tender_reach_rate"),
    "[Entity Median Award Value (NGN)]": lambda w, f, p: entity_kpi(w, f, "median_award_value"),
    "[Contracts (n)]": lambda w, f, p: Decimal(sum(n for _, _, n in contracts(w, f))),
    "[Contracts With Implementation Data]": lambda w, f, p: Decimal(sum(n for _, h, n in contracts(w, f) if h)),
    "[Implementation Coverage Rate]": lambda w, f, p: divide(sum(n for _, h, n in contracts(w, f) if h), sum(n for _, _, n in contracts(w, f))),
    "[Contracts (n)] by [Implementation Data Type]": lambda w, f, p: Decimal(sum(n for t, _, n in contracts(w, f) if t == p["band"])),
    "MetricPopulation[candidate_count]": lambda w, f, p: Decimal(register(w, p["metric"])["candidate_count"]),
    "MetricPopulation[eligible_count]": lambda w, f, p: Decimal(register(w, p["metric"])["eligible_count"]),
    "[Eligible Share]": lambda w, f, p: divide(register(w, p["metric"])["eligible_count"], register(w, p["metric"])["candidate_count"]),
    "DQImpact[records_with_issue]": lambda w, f, p: Decimal(dq(w, p["metric"], p["issue"])["records_with_issue"]),
    "DQImpact[affected_value_ngn]": lambda w, f, p: Decimal(dq(w, p["metric"], p["issue"])["affected_value_ngn"]),
}


def parse_figure(fig):
    """(measure key, filter, params) from a pack row: the slice text and the figure ID carry the parameters."""
    measure, f, p = fig["measure"], {}, {}
    m = re.match(r"^(.*) with N = (\d+)$", measure)
    if m:
        measure, p["n"] = m.group(1), int(m.group(2))
    for part in [s.strip() for s in fig["slice"].split(",")]:
        if part == "none":
            continue
        key, _, val = (x.strip() for x in part.partition("="))
        if key == "method":
            f["method"] = val
        elif key == "buyer":
            f["buyer"] = val
        elif key == "tender_status":
            f["tender_status"] = val
        elif key == "contract_status":
            f["contract_status"] = val
        elif key == "Tender Start Year":
            f["tender_start_year"] = int(val)
        elif key == "Stage":
            p["stage"] = int(val)
        elif key == "population":
            p["population"] = 1 if val == "primary" else 0
        elif key.startswith("Min ") and key.endswith(" n"):
            p["min_n"] = int(val)
        elif key == "metric":
            p["metric"] = val
        elif key == "issue":
            p["issue"] = val
        else:
            raise ValueError(f"{fig['id']}: unknown slice '{part}'")
    fid = fig["id"]
    if m := re.match(r"^(COM-B|BVA-B|IMP-T)(\d+)$", fid):
        p["band"] = int(m.group(2))
    if m := re.match(r"^TIM-D(\d)-(\d)$", fid):
        p["timing_table"] = ("tender_duration", "award_lag", "signature_lag")[int(m.group(1)) - 1]
        p["band"] = int(m.group(2))
    if fid.startswith(("DQ-C-", "DQ-E-", "DQ-P-")):
        p["metric"] = fig["figure"].split(": ", 1)[1]
    return measure, f, p


# ================================================================ tolerance (as in the reconciliation log)
PLACES = {"share": 4, "ratio": 4, "index": 1, "NGN": 0, "days": 1, "count": 1}


def show(v, unit):
    return None if v is None else Decimal(v).quantize(Decimal(1).scaleb(-PLACES[unit]), rounding=ROUND_HALF_UP)


def agrees(expected, computed, unit):
    if expected is None or computed is None:
        return expected is None and computed is None
    e, c = Decimal(expected), Decimal(computed)
    # equal when shown at the log's precision; the absolute 1e-6 only absorbs a float result (SQL percentile_cont is
    # double precision) that lands a hair either side of a rounding boundary
    return show(e, unit) == show(c, unit) or abs(e - c) <= Decimal("1e-6")


def fmt(v, unit):
    if v is None:
        return "(blank)"
    v = Decimal(v)
    if unit == "share":
        return f"{v * 100:.2f}%"
    if unit == "ratio":
        return f"{v:.4f}"
    if unit == "index":
        return f"{v:.1f}"
    if unit == "NGN":
        return f"{v.quantize(Decimal(1), rounding=ROUND_HALF_UP):,}"
    if unit == "days":
        return f"{v:,.1f}".rstrip("0").rstrip(".")
    return f"{v:,.0f}" if v == v.to_integral_value() else f"{v:,.1f}"


# ================================================================ DQ-21 sensitivity (Phase 10.1 result sets)
def r(v, places):
    return None if v is None else Decimal(v).quantize(Decimal(1).scaleb(-places), rounding=ROUND_HALF_UP)


def bn(kobo, places):
    return r(Decimal(kobo) / Decimal(10) ** 11, places)


def ranked(values, key_id):
    """row_number() OVER (ORDER BY value DESC, id): list of (key, value) in rank order."""
    return sorted(values.items(), key=lambda kv: (-kv[1], key_id(kv[0])))


def rs6(w):
    out = []
    flagged_in_sup = sum(1 for i in m_supplier_rows(w, {}) if w.awards["f"][i])
    for label, f in (("1  as published (RS2)", {}), ("2  without DQ-21 flagged awards", {"dq21": "exclude"})):
        idx = m_supplier_rows(w, f)
        v = supplier_values(w, f)
        tot = Decimal(sum(v.values()))
        rk = ranked(v, lambda s: w.suppliers["id"][s])
        share = lambda k: sum(Decimal(x) for _, x in rk[:k]) / tot
        out.append([label, len(idx), flagged_in_sup, bn(tot, 1), r(100 * share(1), 2), r(100 * share(5), 2),
                    r(100 * share(10), 2), r(100 * share(100), 2),
                    r(sum((Decimal(x) / tot) ** 2 for x in v.values()) * 10000, 1),
                    w.suppliers["name"][rk[0][0]], bn(rk[0][1], 2)])
    return out


def rs6b(w):
    rows = []
    for mi, method in enumerate(w.dims["methods"]):
        idx = [i for i in m_supplier_rows(w, {}) if w.awards["m"][i] == mi]
        if not idx:
            continue
        pub = by_key([w.awards["s"][i] for i in idx], [w.awards["v"][i] for i in idx])
        wo_idx = [i for i in idx if not w.awards["f"][i]]
        wo = by_key([w.awards["s"][i] for i in wo_idx], [w.awards["v"][i] for i in wo_idx])
        tp, tw = Decimal(sum(pub.values())), Decimal(sum(wo.values()))
        rows.append((tp, [method, sum(1 for i in idx if w.awards["f"][i]), bn(tp, 2), bn(tw, 2),
                          r(100 * max(pub.values()) / tp, 1), r(100 * max(wo.values()) / tw, 1) if tw else None,
                          r(sum((Decimal(x) / tp) ** 2 for x in pub.values()) * 10000, 0),
                          r(sum((Decimal(x) / tw) ** 2 for x in wo.values()) * 10000, 0) if tw else D0]))
    return [row for _, row in sorted(rows, key=lambda t: -t[0])]


def rs11(w):
    out = []
    ba = w.budget_award
    flagged = sum(ba["f"])
    for label, f in (("1  as published (RS1, RS3)", {}), ("2  without DQ-21 flagged awards", {"dq21": "exclude"})):
        idx = w.rows("budget_award", f)
        bud, aw = sum(ba["bud"][i] for i in idx), sum(ba["aw"][i] for i in idx)
        hi = [i for i in idx if ba["r"][i] > 10]
        hi_aw = sum(ba["aw"][i] for i in hi)
        out.append([label, len(idx), flagged, bn(bud, 1), bn(aw, 1), r(Decimal(aw) / bud, 4),
                    r(percentile_inc([ba["r"][i] for i in idx], 0.5), 4), len(hi), bn(hi_aw, 1),
                    r(100 * Decimal(hi_aw) / aw, 2)])
    return out


def rs11a(w):
    a = w.awards
    fl = [i for i in range(len(a["f"])) if a["f"][i]]
    val = sum(a["v"][i] for i in fl)
    return [[len(fl), sum(1 for i in fl if a["f"][i] & 1), sum(1 for i in fl if a["f"][i] & 2), bn(val, 1),
             r(100 * Decimal(val) / sum(a["v"]), 1), sum(w.budget_award["f"]), len({a["b"][i] for i in fl})]]


def rs11b(w):
    ba = w.budget_award
    idx = [i for i in range(len(ba["r"])) if ba["r"][i] > 10 and not ba["f"][i]]
    val = by_key([ba["b"][i] for i in idx], [ba["aw"][i] for i in idx])
    cnt = by_key([ba["b"][i] for i in idx], [1] * len(idx))
    tot = sum(val.values())
    order = sorted(val, key=lambda b: -val[b])
    out = []
    for b in order[:5]:
        rank = 1 + sum(1 for x in val.values() if x > val[b])
        out.append([rank, w.buyer_id(b), w.buyer_names[b] if b >= 0 else None, cnt[b], bn(val[b], 1),
                    r(100 * Decimal(val[b]) / tot, 1), len(idx), bn(tot, 1)])
    return out


def entity_award_scenarios(w):
    a = w.awards
    idx = [i for i in range(len(a["b"])) if a["b"][i] >= 0]
    pub = by_key([a["b"][i] for i in idx], [a["v"][i] for i in idx])
    wo = {b: 0 for b in pub}
    wo.update(by_key([a["b"][i] for i in idx if not a["f"][i]], [a["v"][i] for i in idx if not a["f"][i]]))
    nfl = {b: 0 for b in pub}
    nfl.update(by_key([a["b"][i] for i in idx if a["f"][i]], [1] * sum(1 for i in idx if a["f"][i])))
    return pub, wo, nfl


def rs7(w):
    pub, wo, _ = entity_award_scenarios(w)
    rp, rw = ranked(pub, lambda b: w.buyer_ids[b]), ranked(wo, lambda b: w.buyer_ids[b])
    tp, tw = Decimal(sum(pub.values())), Decimal(sum(wo.values()))
    return [[n, r(100 * sum(Decimal(x) for _, x in rp[:n]) / tp, 1), r(100 * sum(Decimal(x) for _, x in rw[:n]) / tw, 1),
             bn(tp, 1), bn(tw, 1)] for n in (1, 5, 10, 20, 50, 100)]


def rs7b(w):
    pub, wo, nfl = entity_award_scenarios(w)
    rank_pub = {b: i + 1 for i, (b, _) in enumerate(ranked(pub, lambda b: w.buyer_ids[b]))}
    out = []
    for i, (b, v) in enumerate(ranked(wo, lambda b: w.buyer_ids[b])[:10]):
        out.append([i + 1, rank_pub[b], w.buyer_ids[b], w.buyer_names[b], bn(pub[b], 1), nfl[b], bn(v, 1)])
    return out


SENSITIVITY = {"01/RS6": rs6, "01/RS6b": rs6b, "03/RS11": rs11, "03/RS11a": rs11a, "03/RS11b": rs11b,
               "05/RS7": rs7, "05/RS7b": rs7b}


def same_cell(e, c):
    if e is None or c is None:
        return e is None and c is None
    if isinstance(c, str) or isinstance(e, str) and not re.fullmatch(r"-?\d+(\.\d+)?", e):
        return str(e) == str(c)
    return Decimal(str(e)) == Decimal(str(c))


# ================================================================ manifest
FILE_VIEWS = {
    "dims.json": ("vw_dim_buyer", "vw_dim_procurement_method"), "lifecycle.json": ("vw_lifecycle_stage",),
    "budget.json": ("vw_budget_eligible",), "competition.json": ("vw_competition_eligible",),
    "awards.json": ("vw_award_value_eligible",), "budget_award.json": ("vw_budget_award_comparison",),
    "tender_duration.json": ("vw_tender_duration_eligible",), "award_lag.json": ("vw_award_lag_eligible",),
    "signature_lag.json": ("vw_signature_lag_eligible",), "contracts.json": ("vw_contract_implementation_coverage",),
    "entities.json": ("vw_entity_benchmark",), "registers.json": ("vw_metric_population", "vw_dq_impact"),
}


def recount(w, expected):
    return {
        "dims.json": len(w.dims["buyers"]) + len(w.dims["methods"]), "lifecycle.json": sum(w.lifecycle["n"]),
        "budget.json": sum(w.budget["n"]), "suppliers.json": len(w.suppliers["id"]),
        "competition.json": len(w.competition["b"]), "awards.json": len(w.awards["b"]),
        "budget_award.json": len(w.budget_award["b"]), "tender_duration.json": len(w.tender_duration["b"]),
        "award_lag.json": len(w.award_lag["b"]), "signature_lag.json": len(w.signature_lag["b"]),
        "contracts.json": sum(w.contracts["n"]), "entities.json": len(w.entities["b"]),
        "registers.json": len(w.registers["metric_population"]["rows"]) + len(w.registers["dq_impact"]["rows"]),
        "expected.json": len(expected["pack"]),
    }


# ================================================================ wording
def banned_words():
    text = open(README, encoding="utf-8").read()
    sec = text.split("### 7.3 Words not to use", 1)[1].split("\n## ", 1)[0]
    listed = re.search(r"contain or imply:(.*?)\. Use:", sec, re.S).group(1)
    words = [x.strip(" *\n") for x in re.split(r",", listed.replace("\n", " ")) if x.strip(" *\n")]
    caveats = text.split("## 8. Mandatory caveat text", 1)[1].split("\n## ", 1)[0]
    allowed = re.findall(r"\"([^\"]+)\"", caveats)
    return words, allowed


def word_pattern(word):
    parts = [re.escape(p) for p in word.split("/")]
    stems = []
    for p in parts:
        stems.append(p + r"\w*" if p.startswith("corrupt") or p == "embezzle" else p)
    return re.compile(r"\b(" + "|".join(stems) + r")\b", re.IGNORECASE)


def scan_wording():
    words, allowed = banned_words()
    files = [p for ext in ("html", "js", "css") for p in glob.glob(os.path.join(ROOT, "web", "**", f"*.{ext}"), recursive=True)
             if os.sep + "data" + os.sep not in p and os.sep + "vendor" + os.sep not in p]
    hits = []
    for path in sorted(files):
        text = open(path, encoding="utf-8").read()
        for sentence in allowed:
            text = text.replace(sentence, "")
        for word in words:
            for m in word_pattern(word).finditer(text):
                line = text.count("\n", 0, m.start()) + 1
                hits.append(f"{os.path.relpath(path, ROOT)}:{line}: '{m.group(0)}'")
    return words, len(allowed), [os.path.relpath(p, ROOT) for p in sorted(files)], hits


# ================================================================ main
def main():
    parser = argparse.ArgumentParser(description="Check the web dashboard data against the published figures.")
    parser.add_argument("--role", help="SET ROLE to this role before reading (e.g. nocopo_bi)")
    parser.add_argument("--browser-result", help="result line shown by web/check.html, to record in the report")
    args = parser.parse_args()

    manifest = json.load(open(os.path.join(DATA, "manifest.json"), encoding="utf-8"))
    expected = json.load(open(os.path.join(DATA, "expected.json"), encoding="utf-8"))
    w = Web(DATA)
    failures = []

    # ---- live values (read-only)
    queries = export_web_data.all_queries()
    conninfo = dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5433"),
                    user=os.environ.get("PGUSER", "postgres"), dbname=os.environ.get("PGDATABASE", "nocopo_db"))
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        if args.role:
            conn.execute(psycopg.sql.SQL("SET ROLE {}").format(psycopg.sql.Identifier(args.role)))
        who = conn.execute("SELECT current_user").fetchone()[0]
        live_pack = [list(row) for row in conn.execute(queries["reconciliation_pack"]).fetchall()]
        live_sens = {k: [export_web_data.plain(list(row)) for row in conn.execute(sql).fetchall()]
                     for k, sql in export_web_data.sensitivity_queries().items()}
        live_counts = dict(conn.execute(export_web_data.Q["view_counts"]).fetchall())
        conn.rollback()

    # ---- 1. manifest
    man_rows = []
    counts = recount(w, expected)
    for name, m in manifest["files"].items():
        data = open(os.path.join(DATA, name), "rb").read()
        sha_ok = hashlib.sha256(data).hexdigest() == m["sha256"] and len(data) == m["bytes"]
        live = (sum(live_counts[v] for v in FILE_VIEWS[name]) if name in FILE_VIEWS
                else len(live_pack) if name == "expected.json" else None)
        ok = sha_ok and counts[name] == m["rows"] and (live is None or live == m["rows"])
        if not ok:
            failures.append(f"manifest: {name}")
        man_rows.append(f"| `{name}` | {m['rows']:,} | {counts[name]:,} | {'' if live is None else f'{live:,}'} | "
                        f"{m['bytes'] / 1024:,.1f} | {m['gzip_bytes'] / 1024:,.1f} | {'match' if sha_ok else 'MISMATCH'} | "
                        f"{'PASS' if ok else 'FAIL'} |")
    if set(manifest["files"]) != {os.path.basename(p) for p in glob.glob(os.path.join(DATA, "*.json"))} - {"manifest.json"}:
        failures.append("manifest: the file list differs from web/data/")
    if manifest["source_sha256"] != export_web_data.SOURCE_SHA256:
        failures.append("manifest: source SHA-256 differs from the pinned dataset")

    # ---- 2. reconciliation
    stale = [p["id"] for p, l in zip(expected["pack"], live_pack)
             if [p["id"], p["slice"], p["value"], p["unit"]] != [l[0], l[4], export_web_data.plain(l[5]), l[6]]]
    if len(expected["pack"]) != len(live_pack) or stale:
        failures.append(f"expected.json differs from the live pack: {stale[:5]}")
    rec_rows, passed = [], 0
    for fig, live in zip(expected["pack"], live_pack):
        measure, f, p = parse_figure(fig)
        try:
            got = MEASURES[measure](w, f, p)
        except Exception as exc:          # a figure that cannot be computed is a failure, not a crash
            got, err = None, str(exc)
        else:
            err = ""
        ok = not err and agrees(live[5], got, fig["unit"])
        passed += ok
        if not ok:
            failures.append(f"{fig['id']}: SQL {fmt(live[5], fig['unit'])}, web {fmt(got, fig['unit'])} {err}")
        rec_rows.append(f"| {fig['id']} | {fig['figure']} | {fig['slice']} | {fmt(live[5], fig['unit'])} | "
                        f"{fmt(got, fig['unit'])} | {'PASS' if ok else 'FAIL'} |")

    # ---- 3. sensitivity
    sens_sections, sens_cells, sens_pass = [], 0, 0
    for key, fn in SENSITIVITY.items():
        cols = expected["sensitivity"][key]["cols"]
        exp_rows, live_rows = expected["sensitivity"][key]["rows"], live_sens[key]
        if exp_rows != live_rows:
            failures.append(f"expected.json {key} differs from the live result set")
        got_rows = fn(w)
        lines = ["| " + " | ".join(["cell"] + ["SQL", "web", ""]) + " |", "|---|---|---|---|"]
        if len(got_rows) != len(live_rows):
            failures.append(f"{key}: {len(live_rows)} SQL rows, {len(got_rows)} web rows")
        for ri, (lr, gr) in enumerate(zip(live_rows, got_rows), start=1):
            for c, e, g in zip(cols, lr, gr):
                ok = same_cell(e, g)
                sens_cells += 1
                sens_pass += ok
                if not ok:
                    failures.append(f"{key} row {ri} {c}: SQL {e}, web {g}")
                lines.append(f"| row {ri} `{c}` | {e} | {g} | {'PASS' if ok else 'FAIL'} |")
        sens_sections += [f"### {key}", "", f"{len(live_rows)} row(s) x {len(cols)} column(s).", ""] + lines + [""]

    # ---- 4. browser self-check (kept while expected.json is unchanged)
    exp_sha = manifest["files"]["expected.json"]["sha256"]
    browser = None
    out_path = os.path.join(ROOT, OUTPUT_REL)
    if args.browser_result:
        browser = f"{args.browser_result} (expected.json SHA-256 `{exp_sha[:16]}…`, recorded {datetime.now():%Y-%m-%d %H:%M})"
    elif os.path.exists(out_path):
        old = open(out_path, encoding="utf-8").read()
        m = re.search(r"^\*\*Recorded result:\*\* (.*)$", old, re.M)
        if m and exp_sha[:16] in m.group(1):
            browser = m.group(1)

    # ---- 5. wording
    words, n_allowed, scanned, hits = scan_wording()
    failures += [f"wording: {h}" for h in hits]

    total = len(expected["pack"])
    out = [
        "# Web Dashboard Reconciliation Results",
        "# Nigeria Public Procurement Intelligence",
        "",
        f"> **Generated:** {datetime.now():%Y-%m-%d %H:%M} by `python/web/check_web_data.py` (role `{who}`, read-only)  ",
        f"> **Data:** `web/data/` exported {manifest['generated_at']} by role `{manifest['role']}` from `{manifest['database']}` "
        f"(PostgreSQL {manifest['server_version']}); source SHA-256 `{manifest['source_sha256'][:7]}…{manifest['source_sha256'][-5:]}`  ",
        f"> **Result:** {'PASS' if not failures else 'FAIL'}: manifest {'verified' if not any(x.startswith('manifest') for x in failures) else 'FAILED'}; "
        f"reconciliation {passed}/{total} PASS; DQ-21 sensitivity {sens_pass}/{sens_cells} cells PASS; "
        f"wording {len(hits)} finding(s)",
        "",
        "The figures below are recomputed from the JSON files alone, by Python functions that mirror the DAX measures "
        "(`dashboard/README.md` §5), and compared with the live SQL. The site's JavaScript is checked separately by "
        "`web/check.html` (section 4).",
        "",
        "## 1. Manifest",
        "",
        "Rows: as written to the manifest, recounted from the JSON, and counted live in the source view(s). "
        "Aggregated files (lifecycle, budget, contracts) count the source rows they summarise.",
        "",
        "| File | Manifest rows | JSON rows | Live view rows | KB | gzip KB | SHA-256 and size | Result |",
        "|---|---|---|---|---|---|---|---|",
        *man_rows,
        f"| **Total** | | | | **{manifest['total_bytes'] / 1024:,.1f}** | **{manifest['total_gzip_bytes'] / 1024:,.1f}** | | |",
        "",
        f"## 2. Reconciliation: {passed}/{total} PASS",
        "",
        f"Source: `dashboard/reconciliation_expected_values.sql`, re-run live; `expected.json` "
        f"{'equals' if not stale and len(expected['pack']) == len(live_pack) else 'DIFFERS FROM'} the live values. "
        "Tolerance: counts, days and bands identical; NGN to the whole naira; ratios and shares to four decimals; "
        "index to one decimal. IMP-T3 (transactions only) is 0 in SQL; the web shows 0.",
        "",
        "| ID | Figure | Slice | SQL value | Web value | Result |",
        "|---|---|---|---|---|---|",
        *rec_rows,
        "",
        f"## 3. DQ-21 sensitivity: {sens_pass}/{sens_cells} cells PASS",
        "",
        "The Phase 10.1 result sets (`sql/06_analysis/01`, `03`, `05`), re-run live and recomputed from the JSON with the "
        "DQ-21 flag in `awards.json` and `budget_award.json`. Each cell is compared at the precision the result set rounds to "
        "(NGN billions, percentages); names and IDs exactly.",
        "",
        *sens_sections,
        "## 4. In-browser self-check (`web/check.html`)",
        "",
        "`web/check.html` loads the same JSON with the site's own modules (`js/data.js`, `js/metrics.js`, `js/format.js`) "
        "and compares every figure in `expected.json` (the 177 and the sensitivity cells) under the same tolerance. "
        "Serve `web/` (`python -m http.server --directory web 8000`) and open `http://localhost:8000/check.html`.",
        "",
        f"**Recorded result:** {browser if browser else 'not yet recorded for this expected.json'}",
        "",
        "## 5. Wording scan",
        "",
        f"Words from `dashboard/README.md` §7.3 ({len(words)}): {', '.join(words)}. The {n_allowed} mandatory caveat sentences "
        "of §8 are allowed verbatim. Files scanned: " + (", ".join(f"`{s}`" for s in scanned) if scanned else "none yet") + ".",
        "",
        *(["Findings:", ""] + [f"- {h}" for h in hits] if hits else ["No findings."]),
        "",
    ]
    if failures:
        out += ["## Failures", ""] + [f"- {x}" for x in failures] + [""]
    out += ["---", "", "*Generated by `python/web/check_web_data.py`. Database, raw dataset and existing outputs not modified.*", ""]
    with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out))

    print(f"Manifest: {len(manifest['files'])} files, {'verified' if not any(x.startswith('manifest') for x in failures) else 'FAILED'}")
    print(f"Reconciliation: {passed}/{total} PASS")
    print(f"DQ-21 sensitivity: {sens_pass}/{sens_cells} cells PASS")
    print(f"Browser self-check: {browser or 'not recorded'}")
    print(f"Wording: {len(scanned)} file(s) scanned, {len(hits)} finding(s)")
    for x in failures:
        print("  FAIL " + x)
    print(f"Report: {OUTPUT_REL}")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
