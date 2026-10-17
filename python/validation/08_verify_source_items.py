"""
NOCOPO — Source Verification of Open Items
==========================================
Phase 10: Business Interpretation, Findings & Recommendations
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Before a finding features a record, check it against the raw source. Phase 8
left three observed anomalies open (docs/phase8_analysis/
phase8_business_question_analysis.md §5, O-1):

  A. the NGN 210bn award behind the top supplier (NG-BPP-73422);
  B. Federal Medical Centre, Taraba State (NGN 175.8bn from 10 awards);
  C. HADEJIA-JAMAÄ»ARE RBDA (award about 21 times budget). The name is
     double-encoded UTF-8 in the raw file and is kept as published.

For each item this script prints, from the raw JSON, every release of the
OCIDs involved: tags, budget line, tender, award, contract and implementation
fields. It then applies two mechanical tests used in the classification:
  - sibling comparison: the same supplier's other award from the same buyer;
  - dropped-decimal test: whole-naira award whose value / 100 is close to the
    recorded budget (a two-decimal amount entered without its decimal point).

It also records two measurements used for proposals (not findings):
  - the release-date distribution (evidence for proposed correction C-12);
  - how often the award-to-budget ratio falls near 100 or near 1,000 in the
    budget-to-award population (sizing for proposed issue DQ-21). This is one
    read-only query against analytics.vw_budget_award_comparison.

The script classifies nothing. The classification and the proposals are in
docs/phase10_findings/findings.md §9.

IMPORTANT: READ-ONLY with respect to the raw dataset and the database.

Usage
-----
    python python/validation/08_verify_source_items.py

Connection for the sizing query: the usual PG* environment variables
(defaults: localhost, 5433, postgres, nocopo_db).

Output
------
    docs/phase10_findings/source_verification.md
"""

import hashlib
import json
import os
from collections import Counter
from datetime import datetime
from decimal import Decimal

import psycopg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "NOCOPO dataset", "all07010.json")
OUTPUT = os.path.join(ROOT, "docs", "phase10_findings", "source_verification.md")
EXPECTED_SHA256 = "615146696f51d18f72c12c0152888280c12f280981096aae8408843e7d1bc90c"

# OCIDs were located with read-only queries on the analytics views
# (vw_supplier_award_eligible, vw_award_value_eligible, vw_budget_award_comparison).
ITEM_A_SUPPLIER = "NG-BPP-73422"
ITEM_A_OCIDS = ["ocds-gyl66f-2-005025", "ocds-gyl66f-2-005019"]
ITEM_B_BUYER = "NG-BPP-BPP-NOC-521027034"
ITEM_C_BUYER = "NG-BPP-BPP-NOC-252041001"

SIZING_SQL = """
SELECT CASE WHEN award_to_budget_ratio BETWEEN 90 AND 110 THEN 'ratio 90 to 110'
            WHEN award_to_budget_ratio BETWEEN 900 AND 1100 THEN 'ratio 900 to 1,100'
            WHEN award_to_budget_ratio > 10 THEN 'other ratio above 10'
            ELSE 'ratio 10 or below' END                                   AS ratio_group,
       count(*)                                                            AS ocids,
       count(*) FILTER (WHERE award_value_amount = trunc(award_value_amount)) AS whole_naira_awards,
       round(sum(award_value_amount) / 1e9, 1)                             AS award_ngn_bn,
       count(DISTINCT buyer_id)                                            AS entities
FROM analytics.vw_budget_award_comparison
GROUP BY 1
ORDER BY min(award_to_budget_ratio) DESC
"""


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def amount(obj):
    return (obj or {}).get("amount")


def ngn(x):
    return "" if x is None else f"{Decimal(str(x)):,.2f}"


def text(s, n=110):
    s = " ".join((s or "").split())
    s = s.replace("|", "/")
    return s if len(s) <= n else s[: n - 1] + "…"


def budget_of(r):
    return ((r.get("planning") or {}).get("budget") or {})


def release_rows(ocid, releases):
    """One block of Markdown per release of an OCID."""
    out = []
    for r in releases:
        b = budget_of(r)
        t = r.get("tender") or {}
        out += [f"**{ocid}**, release `{r.get('id')}` (release date {r.get('date', '')[:10]}; "
                f"tags: {', '.join(r.get('tag') or [])})", "",
                "| Section | Field | Value |", "|---|---|---|",
                f"| buyer | id / name | `{(r.get('buyer') or {}).get('id')}` / {text((r.get('buyer') or {}).get('name'))} |"]
        if b:
            out += [f"| planning | budget amount (NGN) | {ngn(amount(b.get('amount')))} |",
                    f"| planning | budget projectID / project | {b.get('projectID')} / {text(b.get('project'))} |",
                    f"| planning | budget description | {text(b.get('description'))} |"]
        else:
            out += ["| planning | budget | (no budget line in this release) |"]
        if t:
            period = t.get("tenderPeriod") or {}
            out += [f"| tender | method / details / status | {t.get('procurementMethod')} / "
                    f"{t.get('procurementMethodDetails')} / {t.get('status')} |",
                    f"| tender | value (NGN) / numberOfTenderers | {ngn(amount(t.get('value')))} / {t.get('numberOfTenderers')} |",
                    f"| tender | tender period | {(period.get('startDate') or '')[:10]} to {(period.get('endDate') or '')[:10]} |",
                    f"| tender | title / description | {text(t.get('title'))} / {text(t.get('description'))} |"]
        for a in r.get("awards") or []:
            sups = "; ".join(f"`{s.get('id')}` {text(s.get('name'), 60)}" for s in a.get("suppliers") or [])
            out += [f"| award `{a.get('id')}` | status / date | {a.get('status')} / {(a.get('date') or '')[:10]} |",
                    f"| award `{a.get('id')}` | value (NGN) | {ngn(amount(a.get('value')))} |",
                    f"| award `{a.get('id')}` | suppliers | {sups} |",
                    f"| award `{a.get('id')}` | title | {text(a.get('title'))} |"]
        for c in r.get("contracts") or []:
            imp = c.get("implementation") or {}
            tx = imp.get("transactions") or []
            tx_total = sum(amount(x.get("value")) or 0 for x in tx)
            out += [f"| contract `{c.get('id')}` | status / date signed | {c.get('status')} / {(c.get('dateSigned') or '')[:10]} |",
                    f"| contract `{c.get('id')}` | value (NGN) | {ngn(amount(c.get('value')))} |",
                    f"| contract `{c.get('id')}` | title | {text(c.get('title'))} |",
                    f"| contract `{c.get('id')}` | implementation | {len(tx)} transaction(s), values summed {ngn(tx_total)}; "
                    f"{len(imp.get('milestones') or [])} milestone(s) |"]
        if not (r.get("contracts") or []):
            out += ["| contract | — | (no contract in this release) |"]
        out.append("")
    return out


def dropped_decimal(award, budget):
    """Whole-naira award whose value / 100 lies within 0.5x to 2x of the budget."""
    if award is None or not budget:
        return None
    a = Decimal(str(award))
    if a != a.to_integral_value():
        return "no (award has a fractional part)"
    ratio = (a / 100) / Decimal(str(budget))
    return f"yes (award / 100 = {ratio:.2f} x budget)" if Decimal("0.5") <= ratio <= 2 else \
        f"no (award / 100 = {ratio:.2f} x budget)"


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    with open(SOURCE, "rb") as fh:
        raw = fh.read()
    sha = hashlib.sha256(raw).hexdigest()
    if sha != EXPECTED_SHA256:
        raise SystemExit(f"Source checksum {sha} does not match the pinned file {EXPECTED_SHA256}.")
    pkg = json.loads(raw)
    releases = pkg["releases"]

    by_ocid = {}
    for r in releases:
        by_ocid.setdefault(r["ocid"], []).append(r)
    for rs in by_ocid.values():
        rs.sort(key=lambda r: int(r["id"]))

    def latest(ocid):
        return by_ocid[ocid][-1]

    def buyer_ocids(buyer_id):
        return sorted(o for o, rs in by_ocid.items() if (rs[-1].get("buyer") or {}).get("id") == buyer_id)

    lines = [
        "# Source Verification of Open Items",
        "# Nigeria Public Procurement Intelligence",
        "",
        f"> **Generated:** {datetime.now():%Y-%m-%d %H:%M} by `python/validation/08_verify_source_items.py`  ",
        f"> **Source:** `NOCOPO dataset/all07010.json`, SHA-256 `{sha[:7]}…{sha[-5:]}` (matches the pinned file)  ",
        "> **Mode:** read-only. Nothing in the raw file, `stg`, `core` or `analytics` was changed.  ",
        "> **Classification and proposals:** `docs/phase10_findings/findings.md` §9 (this file holds the evidence only).",
        "",
        "Values are as published. NGN amounts are shown to two decimals so that whole-naira entries are visible.",
        "",
    ]

    # ---------- Item A ----------
    lines += ["## A. The top supplier's NGN 210bn award", "",
              f"Supplier `{ITEM_A_SUPPLIER}` has two eligible awards (Phase 8, script 01 RS3: NGN 210.29bn in total). "
              "Every release of both OCIDs:", ""]
    for o in ITEM_A_OCIDS:
        lines += release_rows(o, by_ocid[o])
    a_big = amount(latest(ITEM_A_OCIDS[0])["awards"][0]["value"])
    a_small = amount(latest(ITEM_A_OCIDS[1])["awards"][0]["value"])
    first_budget = amount(budget_of(by_ocid[ITEM_A_OCIDS[0]][0]).get("amount"))
    last_budget = amount(budget_of(latest(ITEM_A_OCIDS[0])).get("amount"))
    lines += ["**Mechanical tests**", "",
              "| Test | Result |", "|---|---|",
              f"| Larger award / the same supplier's sibling award from the same buyer | {Decimal(str(a_big)) / Decimal(str(a_small)):,.1f} |",
              f"| Larger award / its budget line in the first release | {Decimal(str(a_big)) / Decimal(str(first_budget)):,.1f} |",
              f"| Larger award / its budget line in the latest release | {Decimal(str(a_big)) / Decimal(str(last_budget)):,.1f} |",
              f"| Larger award / 1,000 (NGN), for comparison with the sibling award | {ngn(Decimal(str(a_big)) / 1000)} |",
              f"| Dropped-decimal test (larger award against its latest budget) | {dropped_decimal(a_big, last_budget)} |",
              ""]

    # ---------- Item B ----------
    b_ocids = buyer_ocids(ITEM_B_BUYER)
    lines += ["## B. Federal Medical Centre, Taraba State", "",
              f"All OCIDs whose latest release names buyer `{ITEM_B_BUYER}` and that carry an award, "
              "with the award value in the latest release:", "",
              "| OCID | Releases | Award status | Award value (NGN) | Budget line (NGN) | Supplier ID | Contract |",
              "|---|---|---|---|---|---|---|"]
    b_big = None
    for o in b_ocids:
        r = latest(o)
        for a in r.get("awards") or []:
            v = amount(a.get("value"))
            if b_big is None or (v or 0) > amount(b_big[1].get("value")):
                b_big = (o, a)
            lines.append(f"| {o} | {len(by_ocid[o])} | {a.get('status')} | {ngn(v)} | "
                         f"{ngn(amount(budget_of(r).get('amount')))} | "
                         f"{'; '.join(s.get('id') or '' for s in a.get('suppliers') or [])} | "
                         f"{'yes' if r.get('contracts') else 'no'} |")
    lines += ["", "Every release of the OCID with the largest award:", ""]
    lines += release_rows(b_big[0], by_ocid[b_big[0]])

    # ---------- Item C ----------
    c_ocids = buyer_ocids(ITEM_C_BUYER)
    rows = []
    for o in c_ocids:
        r = latest(o)
        bud = amount(budget_of(r).get("amount"))
        for a in r.get("awards") or []:
            v = amount(a.get("value"))
            if a.get("status") == "active" and bud and v and Decimal(str(v)) / Decimal(str(bud)) > 10:
                rows.append((o, r, a, bud, v))
    rows.sort(key=lambda t: -t[4])
    raw_name = raw[raw.find(b"HADEJIA-JAMA"): raw.find(b"HADEJIA-JAMA") + 24]
    lines += ["## C. HADEJIA-JAMAÄ»ARE RBDA", "",
              f"Raw bytes of the buyer name: `{raw_name!r}`. The bytes `C3 84 C2 BB` are the UTF-8 encoding of "
              "the characters `Ä»`, which are themselves the UTF-8 bytes of `Ļ` read as Latin-1 "
              "(double encoding). The name is kept exactly as published.", "",
              f"Active awards of `{ITEM_C_BUYER}` whose value is more than ten times the budget line in the same "
              "(latest) release:", "",
              "| OCID | Releases | Budget (NGN) | Award (NGN) | Award / budget | Dropped-decimal test | Implementation transactions, summed (NGN) | Tenderers | Supplier |",
              "|---|---|---|---|---|---|---|---|---|"]
    for o, r, a, bud, v in rows:
        tx = sum(amount(x.get("value")) or 0 for c in r.get("contracts") or []
                 for x in (c.get("implementation") or {}).get("transactions") or [])
        lines.append(f"| {o} | {len(by_ocid[o])} | {ngn(bud)} | {ngn(v)} | {Decimal(str(v)) / Decimal(str(bud)):,.1f} | "
                     f"{dropped_decimal(v, bud)} | {ngn(tx)} | {(r.get('tender') or {}).get('numberOfTenderers')} | "
                     f"{text((a.get('suppliers') or [{}])[0].get('name'), 40)} |")
    passed = [t for t in rows if (dropped_decimal(t[4], t[3]) or "").startswith("yes")]
    lines += ["",
              f"Awards passing the dropped-decimal test: {len(passed)} of {len(rows)}, "
              f"NGN {ngn(sum(Decimal(str(t[4])) for t in passed) / Decimal(10**9))}bn of "
              f"NGN {ngn(sum(Decimal(str(t[4])) for t in rows) / Decimal(10**9))}bn. "
              "Transaction values are shown for context only; their meaning is unresolved (DQ-12) and they are never summed in a metric.",
              "", "Full record of the largest award:", ""]
    lines += release_rows(rows[0][0], by_ocid[rows[0][0]])

    # ---------- Release dates (C-12) ----------
    years = Counter((r.get("date") or "")[:4] for r in releases)
    dates = sorted(r.get("date") for r in releases if r.get("date"))
    lines += ["## D. Release dates (evidence for proposed correction C-12)", "",
              "| Measure | Value |", "|---|---|",
              f"| Package `publishedDate` | {pkg.get('publishedDate')} |",
              f"| Releases | {len(releases):,} |",
              f"| Distinct release `date` values | {len(set(dates)):,} |",
              f"| Releases whose `date` equals the package `publishedDate` | {sum(1 for d in dates if d == pkg.get('publishedDate')):,} |",
              f"| Earliest / latest release `date` | {dates[0]} / {dates[-1]} |"]
    lines += [f"| Releases dated {y} | {n:,} |" for y, n in sorted(years.items())]
    multi = [rs for rs in by_ocid.values() if len(rs) > 1]
    # rs is sorted by integer release ID, so rs[-1] is the release the snapshot treats as latest
    disagree = sum(1 for rs in multi if max(r.get("date") or "" for r in rs) > (rs[-1].get("date") or ""))
    lines += [f"| OCIDs with more than one release | {len(multi):,} |",
              f"| ... where a release with a lower integer ID has a later date | {disagree:,} |"]
    lines += ["",
              "2021-05-03 is the package metadata date, not the date of every release. No metric uses the release date (timing metrics use "
              "event dates; the snapshot orders releases by integer release ID).", ""]

    # ---------- DQ-21 sizing ----------
    conninfo = dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5433"),
                    user=os.environ.get("PGUSER", "postgres"), dbname=os.environ.get("PGDATABASE", "nocopo_db"))
    with psycopg.connect(**conninfo) as conn:
        conn.read_only = True
        cur = conn.execute(SIZING_SQL)
        cols = [d.name for d in cur.description]
        res = cur.fetchall()
    lines += ["## E. Award-to-budget ratios near 100 and near 1,000 (sizing for proposed issue DQ-21)", "",
              "Read-only query on `analytics.vw_budget_award_comparison` (15,574 comparable OCIDs). Phase 8 script 03 "
              "RS10 tested only the ratio near 1,000.", "",
              "| " + " | ".join(cols) + " |", "|" + "|".join("---" for _ in cols) + "|"]
    lines += ["| " + " | ".join(f"{v:,}" if isinstance(v, (int, Decimal)) else str(v) for v in row) + " |" for row in res]
    lines += ["",
              "Whole-naira awards are common at every ratio (see the last row), so a whole-naira amount is not evidence "
              "on its own; the dropped-decimal test in §C also needs the award divided by a hundred to land near the budget.",
              "", "```sql", SIZING_SQL.strip(), "```", "",
              "---", "",
              "*Generated by `python/validation/08_verify_source_items.py`. Raw dataset, stg.*, core.* and analytics.* not modified.*", ""]

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))
    print(f"Report: {os.path.relpath(OUTPUT, ROOT)}")
    print(f"Item C: {len(passed)} of {len(rows)} above-10x awards pass the dropped-decimal test.")


if __name__ == "__main__":
    main()
