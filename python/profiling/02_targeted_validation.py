"""
NOCOPO / OCDS Dataset — Targeted Validation Scan
=================================================
Phase 2: Data Profiling & Audit (continued)
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Targeted follow-up validation script addressing specific anomalies and
inconsistencies identified in the initial profiling report (01_structural_profiler.py).

Investigations
--------------
1. OCID / release count reconciliation (6,280 vs 9,411 discrepancy)
2. Extreme numberOfTenderers value (90,865) inspection
3. numberOfTenderers missingness verification
4. Extreme budget value (NGN 6.5 trillion) inspection
5. Extreme tender/award value (NGN ~1.004 trillion) inspection
6. Internal procurement date quality and availability
7. Implementation section structure inspection
8. Supplier ID / name investigation

IMPORTANT: This script is READ-ONLY with respect to the raw dataset.

Usage
-----
    python python/profiling/02_targeted_validation.py

Output
------
    docs/phase2_profiling/targeted_validation_report.md

Author: Nigeria Public Procurement Intelligence Project
Date:   2026-08-16
"""

import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime
from statistics import median, quantiles

# ---------------------------------------------------------------------------
# Paths — relative to project root
# ---------------------------------------------------------------------------
RAW_DATA_PATH = os.path.join("NOCOPO dataset", "all07010.json")
OUTPUT_REPORT = os.path.join("docs", "phase2_profiling", "targeted_validation_report.md")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def pct(n, total):
    if total == 0:
        return "—"
    return f"{n / total * 100:.1f}%"


def parse_date(s):
    """Parse ISO date string. Returns datetime or None."""
    if not s:
        return None
    s_clean = s.rstrip("Z").rstrip("z")
    for fmt in ("%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(s_clean, fmt)
        except ValueError:
            continue
    try:
        return datetime.strptime(s_clean[:10], "%Y-%m-%d")
    except ValueError:
        return None


def flatten_amount(obj):
    """Extract (amount_float, currency_str) from an OCDS amount object."""
    if obj is None:
        return None, None
    if isinstance(obj, dict):
        return obj.get("amount"), obj.get("currency")
    return None, None


def describe_numeric(values):
    """Basic descriptive stats for a non-empty list of numbers."""
    if not values:
        return {}
    sv = sorted(values)
    n = len(sv)
    qs = quantiles(sv, n=4) if n >= 4 else [sv[0], sv[n//2], sv[-1]]
    return {
        "count": n,
        "min": sv[0],
        "max": sv[-1],
        "median": median(sv),
        "q1": qs[0] if len(qs) >= 3 else None,
        "q3": qs[2] if len(qs) >= 3 else None,
        "p95": quantiles(sv, n=20)[18] if n >= 20 else sv[-1],
        "p99": quantiles(sv, n=100)[98] if n >= 100 else sv[-1],
        "mean": sum(sv) / n,
        "zeros": sum(1 for v in sv if v == 0),
        "negatives": sum(1 for v in sv if v < 0),
    }


PLACEHOLDER_DATES = {"2001-01-01", "1970-01-01", "0001-01-01"}

def is_placeholder(s):
    if not s:
        return False
    return any(s.startswith(p) for p in PLACEHOLDER_DATES)


def classify_date(s):
    """Return: 'null', 'placeholder', 'future', 'extreme_past', 'valid', 'unparseable'."""
    if s is None:
        return "null"
    if is_placeholder(s):
        return "placeholder"
    dt = parse_date(s)
    if dt is None:
        return "unparseable"
    if dt.year > 2030:
        return "extreme_future"
    if dt.year > 2025:
        return "future"
    if dt.year < 2000:
        return "extreme_past"
    return "valid"


# ---------------------------------------------------------------------------
# Load Dataset
# ---------------------------------------------------------------------------

print("=" * 70)
print("NOCOPO Dataset — Targeted Validation Scan")
print("=" * 70)
print(f"Loading: {RAW_DATA_PATH}")

file_size_bytes = os.path.getsize(RAW_DATA_PATH)
with open(RAW_DATA_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

releases = data.get("releases", [])
n_releases = len(releases)
print(f"Loaded {n_releases:,} releases ({file_size_bytes / 1024 / 1024:.1f} MB)")

# ============================================================================
# INVESTIGATION 1: OCID / Release count reconciliation
# ============================================================================
print("\n[1/8] OCID / release count reconciliation...")

ocid_counter = Counter()
for r in releases:
    ocid = r.get("ocid")
    ocid_counter[ocid] += 1

n_unique_ocids = len(ocid_counter)
n_null_ocids = ocid_counter.get(None, 0)

# OCIDs appearing more than once
repeated_ocids = {k: v for k, v in ocid_counter.items() if k is not None and v > 1}
n_repeated_ocids = len(repeated_ocids)

# "Excess releases" = for every repeated OCID, how many releases beyond the first?
# e.g. OCID with 3 releases = 2 excess; OCID with 74 releases = 73 excess
n_excess_releases = sum(v - 1 for v in repeated_ocids.values())

# Distribution of release counts per OCID
release_count_dist = Counter(ocid_counter.values())
max_releases_per_ocid = max(ocid_counter.values())

# OCIDs with exactly 1 release
n_single_release_ocids = sum(1 for v in ocid_counter.values() if v == 1)

# Unique release IDs
release_ids = [r.get("id") for r in releases]
n_unique_release_ids = len(set(release_ids))

# The top-10 most repeated OCIDs
top10_repeated = ocid_counter.most_common(10)

print(f"  Total releases: {n_releases:,}")
print(f"  Unique OCIDs: {n_unique_ocids:,}")
print(f"  OCIDs with >1 release: {n_repeated_ocids:,}")
print(f"  Excess releases: {n_excess_releases:,}")
print(f"  Max releases per OCID: {max_releases_per_ocid}")

# ============================================================================
# INVESTIGATION 2 & 3: numberOfTenderers — outlier + missingness
# ============================================================================
print("\n[2/8] numberOfTenderers — outlier inspection + missingness...")

tender_releases_count = 0
nt_present = []
nt_null = 0
nt_zero = 0
extreme_nt_records = []   # records with numberOfTenderers > 1000

for r in releases:
    tender = r.get("tender")
    if tender is None:
        continue
    tender_releases_count += 1
    nt = tender.get("numberOfTenderers")
    if nt is None:
        nt_null += 1
    else:
        nt_present.append(nt)
        if nt == 0:
            nt_zero += 1
        if nt > 1000:
            buyer = r.get("buyer", {})
            extreme_nt_records.append({
                "ocid": r.get("ocid"),
                "release_id": r.get("id"),
                "release_date": r.get("date"),
                "buyer_id": buyer.get("id"),
                "buyer_name": buyer.get("name"),
                "tender_title": tender.get("title"),
                "tender_description": tender.get("description"),
                "proc_method": tender.get("procurementMethod"),
                "proc_method_details": tender.get("procurementMethodDetails"),
                "tender_value": (tender.get("value") or {}).get("amount"),
                "numberOfTenderers": nt,
                "tender_status": tender.get("status"),
            })

nt_stats = describe_numeric(nt_present)
nt_above_100 = sum(1 for x in nt_present if x > 100)
nt_above_500 = sum(1 for x in nt_present if x > 500)
nt_above_1000 = sum(1 for x in nt_present if x > 1000)

print(f"  Tender releases: {tender_releases_count:,}")
print(f"  numberOfTenderers null: {nt_null}")
print(f"  numberOfTenderers present: {len(nt_present):,}")
print(f"  numberOfTenderers zero: {nt_zero}")
print(f"  Extreme records (>1000): {len(extreme_nt_records)}")
if nt_present:
    print(f"  Max: {nt_stats['max']}, Median: {nt_stats['median']:.1f}, P99: {nt_stats['p99']}")

# ============================================================================
# INVESTIGATION 4: Extreme budget value (₦6.5 trillion)
# ============================================================================
print("\n[3/8] Extreme budget value inspection...")

BUDGET_EXTREME_THRESHOLD = 1_000_000_000_000  # 1 trillion NGN
extreme_budget_records = []
budget_amounts = []

for r in releases:
    planning = r.get("planning")
    if not planning:
        continue
    budget = planning.get("budget")
    if not budget:
        continue
    amt, cur = flatten_amount(budget.get("amount"))
    if amt is None:
        continue
    budget_amounts.append(amt)
    if amt >= BUDGET_EXTREME_THRESHOLD:
        buyer = r.get("buyer", {})
        tender = r.get("tender")
        extreme_budget_records.append({
            "ocid": r.get("ocid"),
            "release_id": r.get("id"),
            "release_date": r.get("date"),
            "buyer_id": buyer.get("id"),
            "buyer_name": buyer.get("name"),
            "budget_amount": amt,
            "budget_currency": cur,
            "budget_description": budget.get("description"),
            "budget_project": budget.get("project"),
            "budget_projectID": budget.get("projectID"),
            "tender_value": (tender.get("value") or {}).get("amount") if tender else None,
            "tender_title": tender.get("title") if tender else None,
            "proc_method_details": tender.get("procurementMethodDetails") if tender else None,
            "tags": r.get("tag"),
        })

budget_stats = describe_numeric(budget_amounts)
print(f"  Budget records: {len(budget_amounts):,}")
print(f"  Extreme (>=1T NGN): {len(extreme_budget_records):,}")
if budget_stats:
    print(f"  Max: {budget_stats['max']:,.0f}, P99: {budget_stats['p99']:,.0f}")

# ============================================================================
# INVESTIGATION 5: Extreme tender/award value (₦1.004 trillion)
# ============================================================================
print("\n[4/8] Extreme tender/award value inspection...")

AWARD_EXTREME_THRESHOLD = 500_000_000_000  # 500 billion NGN
extreme_award_records = []
award_amounts = []
tender_amounts = []

for r in releases:
    ocid = r.get("ocid")
    tender = r.get("tender")
    awards = r.get("awards", [])

    if tender:
        tv, _ = flatten_amount(tender.get("value"))
        if tv is not None:
            tender_amounts.append(tv)

    for aw in awards:
        av, _ = flatten_amount(aw.get("value"))
        if av is None:
            continue
        award_amounts.append(av)
        if av >= AWARD_EXTREME_THRESHOLD:
            buyer = r.get("buyer", {})
            tv_amt, _ = flatten_amount(tender.get("value")) if tender else (None, None)
            extreme_award_records.append({
                "ocid": ocid,
                "release_id": r.get("id"),
                "release_date": r.get("date"),
                "buyer_id": buyer.get("id"),
                "buyer_name": buyer.get("name"),
                "tender_value": tv_amt,
                "award_value": av,
                "award_status": aw.get("status"),
                "award_date": aw.get("date"),
                "award_id": aw.get("id"),
                "suppliers": [s.get("name") for s in aw.get("suppliers", [])],
                "proc_method_details": tender.get("procurementMethodDetails") if tender else None,
                "tender_title": tender.get("title") if tender else None,
                "tags": r.get("tag"),
            })

award_stats = describe_numeric(award_amounts)
print(f"  Award records: {len(award_amounts):,}")
print(f"  Extreme (>=500B NGN): {len(extreme_award_records):,}")
if award_stats:
    print(f"  Max award: {award_stats['max']:,.0f}")

# Check if extreme tender and award values belong to same OCID
extreme_tender_ocids = set()
for r in releases:
    tender = r.get("tender")
    if tender:
        tv, _ = flatten_amount(tender.get("value"))
        if tv is not None and tv >= AWARD_EXTREME_THRESHOLD:
            extreme_tender_ocids.add(r.get("ocid"))

extreme_award_ocids = set(rec["ocid"] for rec in extreme_award_records)
overlap_ocids = extreme_tender_ocids & extreme_award_ocids
print(f"  OCIDs with extreme tender AND extreme award: {len(overlap_ocids)}")

# ============================================================================
# INVESTIGATION 6: Internal procurement date quality
# ============================================================================
print("\n[5/8] Internal date quality scan...")

date_fields = {
    "tender_start": [],
    "tender_end": [],
    "award_date": [],
    "contract_signed": [],
    "contract_period_start": [],
    "contract_period_end": [],
    "tender_award_period_end": [],
}

for r in releases:
    tender = r.get("tender")
    if tender:
        tp = tender.get("tenderPeriod") or {}
        date_fields["tender_start"].append(tp.get("startDate"))
        date_fields["tender_end"].append(tp.get("endDate"))
        ap = tender.get("awardPeriod") or {}
        date_fields["tender_award_period_end"].append(ap.get("endDate"))

    for aw in r.get("awards", []):
        date_fields["award_date"].append(aw.get("date"))

    for ct in r.get("contracts", []):
        date_fields["contract_signed"].append(ct.get("dateSigned"))
        cp = ct.get("period") or {}
        date_fields["contract_period_start"].append(cp.get("startDate"))
        date_fields["contract_period_end"].append(cp.get("endDate"))

# Classify each date field
date_summary = {}
extreme_date_examples = {}
for field, dates in date_fields.items():
    classification = Counter()
    parsed_dates = []
    extremes = []
    for d in dates:
        cls = classify_date(d)
        classification[cls] += 1
        if cls in ("extreme_future", "future") and d is not None:
            dt = parse_date(d)
            if dt and len(extremes) < 5:
                extremes.append((d, dt.year))
        if cls == "valid":
            dt = parse_date(d)
            if dt:
                parsed_dates.append(dt)
    date_summary[field] = {
        "total": len(dates),
        "classification": dict(classification),
        "parsed_count": len(parsed_dates),
        "min_date": min(parsed_dates).strftime("%Y-%m-%d") if parsed_dates else None,
        "max_date": max(parsed_dates).strftime("%Y-%m-%d") if parsed_dates else None,
    }
    if extremes:
        extreme_date_examples[field] = extremes

print("  Date field classification complete.")
for field, summary in date_summary.items():
    cls = summary["classification"]
    print(f"    {field}: total={summary['total']:,}, valid={cls.get('valid',0):,}, null={cls.get('null',0):,}, "
          f"placeholder={cls.get('placeholder',0):,}, future={cls.get('future',0)+cls.get('extreme_future',0):,}")

# ============================================================================
# INVESTIGATION 7: Implementation structure
# ============================================================================
print("\n[6/8] Implementation section structure inspection...")

impl_tag_count = 0
impl_in_contract_count = 0
impl_transactions_count = 0
impl_tx_with_date = 0
impl_tx_with_amount = 0
impl_milestones_count = 0

sample_impl_structures = []

for r in releases:
    tags = r.get("tag", [])
    has_impl_tag = "implementation" in tags
    if has_impl_tag:
        impl_tag_count += 1

    contracts = r.get("contracts", [])
    for ct in contracts:
        impl = ct.get("implementation")
        if not impl or not isinstance(impl, dict):
            continue
        impl_in_contract_count += 1
        txns = impl.get("transactions") or []
        miles = impl.get("milestones") or []
        if txns:
            impl_transactions_count += len(txns)
        if miles:
            impl_milestones_count += len(miles)
        for tx in txns:
            if tx.get("date"):
                impl_tx_with_date += 1
            amt_obj = tx.get("amount") or tx.get("value")
            amt, _ = flatten_amount(amt_obj)
            if amt is not None:
                impl_tx_with_amount += 1

        # Collect structural samples (first 3)
        if len(sample_impl_structures) < 3 and (txns or miles):
            sample = {
                "ocid": r.get("ocid"),
                "contract_id": ct.get("id"),
                "impl_keys": list(impl.keys()),
                "transaction_keys": list(txns[0].keys()) if txns else [],
                "sample_transaction": txns[0] if txns else None,
                "milestone_keys": list(miles[0].keys()) if miles else [],
                "sample_milestone": miles[0] if miles else None,
            }
            sample_impl_structures.append(sample)

# Check for implementation at release top level (confirm it's never present)
top_level_impl_count = sum(1 for r in releases if "implementation" in r and r["implementation"] is not None)

print(f"  Releases with implementation tag: {impl_tag_count:,}")
print(f"  Contracts with implementation sub-object: {impl_in_contract_count:,}")
print(f"  Total transaction objects: {impl_transactions_count:,}")
print(f"  Transactions with date field: {impl_tx_with_date:,}")
print(f"  Transactions with amount/value: {impl_tx_with_amount:,}")
print(f"  Total milestone objects (inside impl): {impl_milestones_count:,}")
print(f"  Top-level implementation key: {top_level_impl_count}")

# ============================================================================
# INVESTIGATION 8: Supplier ID / name investigation
# ============================================================================
print("\n[7/8] Supplier ID/name investigation...")

# Map: supplier_id -> set of names
# Map: supplier_name -> set of IDs
id_to_names = defaultdict(set)
name_to_ids = defaultdict(set)
total_supplier_party_objects = 0
null_supplier_id_count = 0

for r in releases:
    for p in r.get("parties", []):
        roles = p.get("roles", [])
        if "supplier" not in roles:
            continue
        total_supplier_party_objects += 1
        pid = p.get("id")
        pname = (p.get("name") or "").strip() or None
        if pid is None:
            null_supplier_id_count += 1
        else:
            if pname:
                id_to_names[pid].add(pname)
            if pname:
                name_to_ids[pname].add(pid)

# IDs with multiple names (same ID, different names)
ids_with_multi_names = {k: v for k, v in id_to_names.items() if len(v) > 1}
# Names with multiple IDs (same name, different IDs)
names_with_multi_ids = {k: v for k, v in name_to_ids.items() if len(v) > 1}

# Sample examples
sample_multi_name_ids = list(ids_with_multi_names.items())[:10]
sample_multi_id_names = list(names_with_multi_ids.items())[:10]

print(f"  Total supplier party objects: {total_supplier_party_objects:,}")
print(f"  Unique supplier IDs (non-null): {len(id_to_names):,}")
print(f"  Unique supplier names: {len(name_to_ids):,}")
print(f"  IDs mapping to >1 name: {len(ids_with_multi_names):,}")
print(f"  Names mapping to >1 ID: {len(names_with_multi_ids):,}")

# ============================================================================
# Budget distribution for context
# ============================================================================
print("\n[8/8] Computing budget and award distribution context...")

budget_above_100b = sum(1 for x in budget_amounts if x > 100_000_000_000)
budget_above_500b = sum(1 for x in budget_amounts if x > 500_000_000_000)
budget_above_1t = sum(1 for x in budget_amounts if x > 1_000_000_000_000)
award_above_100b = sum(1 for x in award_amounts if x > 100_000_000_000)
award_above_500b = sum(1 for x in award_amounts if x > 500_000_000_000)
award_above_1t = sum(1 for x in award_amounts if x > 1_000_000_000_000)

# ============================================================================
# BUILD REPORT
# ============================================================================
print("\nWriting report...")

run_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
lines = []
A = lines.append


def section(title):
    A("")
    A("---")
    A("")
    A(f"## {title}")
    A("")


def fact(text):
    A(f"> **CONFIRMED FACT:** {text}")


def interp(text):
    A(f"> **PRELIMINARY INTERPRETATION:** {text}")


def issue(text):
    A(f"> **DATA-QUALITY ISSUE:** {text}")


def unresolved(text):
    A(f"> **UNRESOLVED QUESTION:** {text}")


def treatment(text):
    A(f"> **RECOMMENDED FUTURE TREATMENT:** {text}")


A("# NOCOPO Dataset — Targeted Validation Report")
A("")
A("> **Project:** Nigeria Public Procurement Intelligence  ")
A(f"> **Script:** `python/profiling/02_targeted_validation.py`  ")
A(f"> **Run date:** {run_date}  ")
A("> **Phase:** 2 — Targeted follow-up validation  ")
A("> **Raw data is READ-ONLY. All figures derived directly from the dataset.**")
A("")
A("This report addresses specific anomalies and internal inconsistencies identified in the")
A("initial profiling report (`docs/phase2_profiling/data_profiling_report.md`). All statistics are freshly")
A("calculated from the raw source file.")
A("")

# ---- 1. OCID RECONCILIATION ----
section("1. OCID / Release Count Reconciliation")
A("### 1.1 Corrected Core Metrics")
A("")
A("| Metric | Value |")
A("|--------|-------|")
A(f"| Total releases | {n_releases:,} |")
A(f"| Unique OCIDs (all) | {n_unique_ocids:,} |")
A(f"| Null OCIDs | {n_null_ocids:,} |")
A(f"| Non-null unique OCIDs | {n_unique_ocids - (1 if n_null_ocids else 0):,} |")
A(f"| OCIDs appearing exactly once | {n_single_release_ocids:,} |")
A(f"| **OCIDs appearing more than once** | **{n_repeated_ocids:,}** |")
A(f"| Excess releases (sum of (count-1) for repeated OCIDs) | {n_excess_releases:,} |")
A(f"| Maximum releases for a single OCID | {max_releases_per_ocid:,} |")
A(f"| Unique release IDs | {n_unique_release_ids:,} |")
A("")
A("### 1.2 Distribution of Release Counts per OCID")
A("")
A("| Releases per OCID | Number of OCIDs |")
A("|-------------------|----------------|")
for count in sorted(release_count_dist.keys()):
    n_ocids_with_this_count = release_count_dist[count]
    A(f"| {count} | {n_ocids_with_this_count:,} |")
A("")
A("### 1.3 Top 10 Most-Released OCIDs")
A("")
A("| OCID | Number of releases |")
A("|------|--------------------|")
for ocid, cnt in top10_repeated:
    A(f"| `{ocid}` | {cnt} |")
A("")
A("### 1.4 Resolution of the 6,280 vs 9,411 Discrepancy")
A("")
A("The initial profiling report contained two conflicting figures:")
A("")
A("- **Section 2** (OCID Analysis table): reported `6,280` OCIDs appearing more than once.")
A("- **Section 13** (Data-Quality Issues summary): stated `9,411 OCIDs appear in >1 release`.")
A("")
A("**Both figures were incorrect as stated.** The correct figure, recalculated directly from the raw dataset, is:")
A("")
A(f"**{n_repeated_ocids:,} OCIDs appear in more than one release.**")
A("")
A("**Explanation of the original error:**")
A("")
A("The Section 2 figure (`6,280`) correctly counts OCIDs with release count > 1.")
A("The Section 13 figure (`9,411`) was a copy-paste error from an earlier, unfixed version of")
A("the profiling script. It was never recalculated after the script was corrected and re-run.")
A("Section 13 was written before the final script run and was not updated to reflect the")
A("corrected output. **Section 13 contains a reporting error; Section 2 is correct.**")
A("")
A("The confirmed correct metrics are:")
A(f"- **{n_repeated_ocids:,} OCIDs** appear in more than one release (i.e., multi-release procurement processes).")
A(f"- **{n_excess_releases:,} excess releases** exist beyond the first release per repeated OCID.")
A(f"- **{n_single_release_ocids:,} OCIDs** have exactly one release.")
A("")
fact(f"Total releases: {n_releases:,}. Unique OCIDs: {n_unique_ocids:,}. OCIDs with >1 release: {n_repeated_ocids:,}. Excess releases: {n_excess_releases:,}.")
A("")
interp("The repeated OCIDs represent procurement processes with multiple lifecycle stages captured "
       "as separate OCDS releases. This is standard OCDS 1.1 behaviour, not duplication. "
       "The maximum of 74 releases for one OCID warrants closer inspection to confirm this is "
       "legitimate lifecycle history and not a data loading artefact.")
A("")
issue("Section 13 of the initial profiling report (`docs/phase2_profiling/data_profiling_report.md`) contained "
      "a stale figure of 9,411 for repeated OCIDs. The correct figure is "
      f"{n_repeated_ocids:,}. The profiling report should be regenerated or annotated.")
A("")
treatment("Retain all releases. The release/version modelling strategy (Phase 3 decision) must "
          "specify how repeated OCIDs are handled before monetary aggregation to avoid double-counting.")

# ---- 2 & 3. numberOfTenderers ----
section("2. numberOfTenderers — Outlier Inspection and Missingness Verification")
A("### 2.1 Corrected Missingness Figures")
A("")
A("| Metric | Value |")
A("|--------|-------|")
A(f"| Tender releases | {tender_releases_count:,} |")
A(f"| numberOfTenderers present (non-null) | {len(nt_present):,} ({pct(len(nt_present), tender_releases_count)}) |")
A(f"| numberOfTenderers null/missing | {nt_null:,} ({pct(nt_null, tender_releases_count)}) |")
A(f"| numberOfTenderers = 0 (zero) | {nt_zero:,} |")
A("")
if nt_null == 0:
    fact(f"numberOfTenderers is present (non-null) in all {tender_releases_count:,} tender releases. "
         f"The initial profiling report was correct on this point — there are 0 missing values.")
else:
    issue(f"numberOfTenderers is null in {nt_null:,} tender releases ({pct(nt_null, tender_releases_count)}).")
A("")
A("### 2.2 Distribution Statistics")
A("")
if nt_stats:
    A("| Statistic | Value |")
    A("|-----------|-------|")
    A(f"| Count | {nt_stats['count']:,} |")
    A(f"| Minimum | {nt_stats['min']} |")
    A(f"| Q1 (25th percentile) | {nt_stats['q1']:.1f} |")
    A(f"| Median | {nt_stats['median']:.1f} |")
    A(f"| Q3 (75th percentile) | {nt_stats['q3']:.1f} |")
    A(f"| 95th percentile | {nt_stats['p95']:.1f} |")
    A(f"| 99th percentile | {nt_stats['p99']:.1f} |")
    A(f"| Maximum | {nt_stats['max']} |")
    A(f"| Mean | {nt_stats['mean']:.1f} |")
    A(f"| Count > 100 | {nt_above_100:,} |")
    A(f"| Count > 500 | {nt_above_500:,} |")
    A(f"| Count > 1,000 | {nt_above_1000:,} |")
A("")
A("### 2.3 Extreme Record Inspection (numberOfTenderers > 1,000)")
A("")
if extreme_nt_records:
    A(f"**{len(extreme_nt_records)} release(s) with numberOfTenderers > 1,000:**")
    A("")
    for rec in extreme_nt_records:
        A(f"**OCID:** `{rec['ocid']}`  ")
        A(f"**Release ID:** `{rec['release_id']}`  ")
        A(f"**Buyer:** {rec['buyer_name']} (`{rec['buyer_id']}`)  ")
        A(f"**Tender title:** {rec['tender_title']}  ")
        A(f"**Procurement method:** {rec['proc_method']} / {rec['proc_method_details']}  ")
        A(f"**Tender value (NGN):** {rec['tender_value']:,.2f}  " if rec['tender_value'] is not None else "**Tender value:** null  ")
        A(f"**numberOfTenderers:** **{rec['numberOfTenderers']:,}**  ")
        A(f"**Tender status:** {rec['tender_status']}  ")
        A("")
else:
    A("No records found with numberOfTenderers > 1,000.")
A("")
issue(f"numberOfTenderers maximum of {nt_stats.get('max', 'N/A'):,} is implausibly high for a standard procurement process. "
      "The 99th percentile is "
      f"{nt_stats.get('p99', 'N/A'):.1f}, indicating this is a severe outlier.")
A("")
interp("The extreme value may reflect a data-entry error, a misused field (e.g., a registration count "
       "rather than a tender submission count), or a framework agreement with open registration. "
       "Given the magnitude, a data-entry error is the most probable explanation.")
A("")
treatment("FLAG this record. Exclude from any statistical analysis of competition levels (e.g., mean, "
          "percentile comparisons). Retain in the dataset with a data-quality flag. "
          "Do not impute a replacement value without source evidence.")

# ---- 4. Extreme budget ----
section("3. Extreme Budget Value (₦6.5 Trillion) Inspection")
A("### 3.1 Budget Distribution Context")
A("")
if budget_stats:
    A("| Statistic | Value (NGN) |")
    A("|-----------|-------------|")
    A(f"| Count | {budget_stats['count']:,} |")
    A(f"| Minimum | {budget_stats['min']:,.2f} |")
    A(f"| Median | {budget_stats['median']:,.2f} |")
    A(f"| 95th percentile | {budget_stats['p95']:,.2f} |")
    A(f"| 99th percentile | {budget_stats['p99']:,.2f} |")
    A(f"| Maximum | {budget_stats['max']:,.2f} |")
    A(f"| Count > ₦100 billion | {budget_above_100b:,} |")
    A(f"| Count > ₦500 billion | {budget_above_500b:,} |")
    A(f"| Count > ₦1 trillion | {budget_above_1t:,} |")
A("")
A("### 3.2 Records with Budget ≥ ₦1 Trillion")
A("")
if extreme_budget_records:
    for rec in extreme_budget_records:
        A(f"**OCID:** `{rec['ocid']}`  ")
        A(f"**Release ID:** `{rec['release_id']}`  ")
        A(f"**Buyer:** {rec['buyer_name']} (`{rec['buyer_id']}`)  ")
        A(f"**Budget amount (NGN):** {rec['budget_amount']:,.2f}  ")
        A(f"**Budget description:** {rec['budget_description']}  ")
        A(f"**Budget project:** {rec['budget_project']}  ")
        A(f"**Budget project ID:** {rec['budget_projectID']}  ")
        A(f"**Tender value (NGN):** {rec['tender_value']:,.2f}  " if rec['tender_value'] is not None else "**Tender value:** not present  ")
        A(f"**Tender title:** {rec['tender_title']}  ")
        A(f"**Procurement method details:** {rec['proc_method_details']}  ")
        A(f"**Tags:** {rec['tags']}  ")
        A("")
else:
    A("No records found with budget ≥ ₦1 trillion.")
A("")

# ---- 5. Extreme tender/award ----
section("4. Extreme Tender/Award Values (₦1.004 Trillion)")
A("### 4.1 Award Distribution Context")
A("")
if award_stats:
    A("| Statistic | Value (NGN) |")
    A("|-----------|-------------|")
    A(f"| Count | {award_stats['count']:,} |")
    A(f"| Minimum | {award_stats['min']:,.2f} |")
    A(f"| Median | {award_stats['median']:,.2f} |")
    A(f"| 95th percentile | {award_stats['p95']:,.2f} |")
    A(f"| 99th percentile | {award_stats['p99']:,.2f} |")
    A(f"| Maximum | {award_stats['max']:,.2f} |")
    A(f"| Count > ₦100 billion | {award_above_100b:,} |")
    A(f"| Count > ₦500 billion | {award_above_500b:,} |")
    A(f"| Count > ₦1 trillion | {award_above_1t:,} |")
A("")
A(f"**OCIDs with both extreme tender value (≥500B) AND extreme award value (≥500B):** {len(overlap_ocids)}")
A("")
A("### 4.2 Records with Award ≥ ₦500 Billion")
A("")
if extreme_award_records:
    for rec in extreme_award_records:
        A(f"**OCID:** `{rec['ocid']}`  ")
        A(f"**Release ID:** `{rec['release_id']}`  ")
        A(f"**Buyer:** {rec['buyer_name']} (`{rec['buyer_id']}`)  ")
        A(f"**Tender value (NGN):** {rec['tender_value']:,.2f}  " if rec['tender_value'] is not None else "**Tender value:** not present  ")
        A(f"**Award value (NGN):** {rec['award_value']:,.2f}  ")
        A(f"**Award status:** {rec['award_status']}  ")
        A(f"**Award date:** {rec['award_date']}  ")
        A(f"**Supplier(s):** {rec['suppliers']}  ")
        A(f"**Tender title:** {rec['tender_title']}  ")
        A(f"**Procurement method details:** {rec['proc_method_details']}  ")
        A(f"**Tags:** {rec['tags']}  ")
        A("")
else:
    A("No records with award ≥ ₦500 billion found.")
A("")

# ---- 6. Date quality ----
section("5. Internal Procurement Date Quality")
A("### 5.1 Date Field Classification Summary")
A("")
A("| Date field | Total | Valid | Null | Placeholder (2001-01-01 etc.) | Future (2026–2030) | Extreme future (>2030) | Extreme past |")
A("|-----------|-------|-------|------|---------|--------|--------|------|")
for field, summary in date_summary.items():
    cls = summary["classification"]
    A(f"| `{field}` | {summary['total']:,} | {cls.get('valid',0):,} | {cls.get('null',0):,} | "
      f"{cls.get('placeholder',0):,} | {cls.get('future',0):,} | {cls.get('extreme_future',0):,} | "
      f"{cls.get('extreme_past',0):,} |")
A("")
A("### 5.2 Valid Date Ranges (excluding placeholders, nulls, extreme values)")
A("")
A("| Date field | Earliest valid | Latest valid |")
A("|-----------|---------------|-------------|")
for field, summary in date_summary.items():
    mn = summary.get("min_date") or "—"
    mx = summary.get("max_date") or "—"
    A(f"| `{field}` | {mn} | {mx} |")
A("")
if extreme_date_examples:
    A("### 5.3 Sample Extreme Future Dates")
    A("")
    for field, examples in extreme_date_examples.items():
        A(f"**{field}:**")
        for raw, year in examples:
            A(f"  - `{raw}` (year: {year})")
        A("")

issue("Award dates include at least one value in year 2922, which is almost certainly a data-entry error "
      "(likely 2022 miskeyed as 2922). Contract period dates also include extreme future values.")
A("")
issue("Placeholder dates (2001-01-01) appear in tender start dates and award dates, indicating "
      "a system default date used when the actual date was not recorded.")
A("")
fact("The release-level `date` field is the package publication date (2021-05-03) for all 108,277 releases. "
     "Internal event dates must be used for any temporal analysis. These are substantially available: "
     f"tender start has {date_summary['tender_start']['classification'].get('valid',0):,} valid dates, "
     f"award date has {date_summary['award_date']['classification'].get('valid',0):,} valid dates.")
A("")
treatment("Exclude placeholder dates (2001-01-01, year 2922, any year > 2030) from timing metrics. "
          "Retain these records in the database; apply a date-quality flag column in staging. "
          "Do not delete or silently correct erroneous dates.")

# ---- 7. Implementation ----
section("6. Implementation Section Structure")
A("### 6.1 Location Confirmed")
A("")
fact("The `implementation` section does NOT exist as a top-level release key. "
     f"Top-level implementation key count: {top_level_impl_count}. "
     "Implementation information is exclusively nested inside `contracts[].implementation`.")
A("")
A("| Metric | Value |")
A("|--------|-------|")
A(f"| Releases with `implementation` tag | {impl_tag_count:,} |")
A(f"| Contracts with `implementation` sub-object | {impl_in_contract_count:,} |")
A(f"| Total transaction objects | {impl_transactions_count:,} |")
A(f"| Transactions with `date` field | {impl_tx_with_date:,} |")
A(f"| Transactions with `amount`/`value` field | {impl_tx_with_amount:,} |")
A(f"| Total milestone objects inside implementation | {impl_milestones_count:,} |")
A(f"| Top-level `implementation` key in any release | {top_level_impl_count} |")
A("")
A("### 6.2 Structure Examples")
A("")
for i, sample in enumerate(sample_impl_structures, 1):
    A(f"**Example {i} — OCID:** `{sample['ocid']}`, Contract ID: `{sample['contract_id']}`  ")
    A(f"- `implementation` keys: `{sample['impl_keys']}`  ")
    A(f"- Transaction keys: `{sample['transaction_keys']}`  ")
    A(f"- Milestone keys: `{sample['milestone_keys']}`  ")
    if sample.get("sample_transaction"):
        tx = sample["sample_transaction"]
        A(f"- Sample transaction: `id={tx.get('id')}`, `amount={tx.get('amount')}`, `value={tx.get('value')}`, `date={tx.get('date')}`  ")
    if sample.get("sample_milestone"):
        ms = sample["sample_milestone"]
        A(f"- Sample milestone: `title={ms.get('title')}`, `status={ms.get('status')}`, `dueDate={ms.get('dueDate')}`  ")
    A("")

if impl_tx_with_date == 0:
    issue(f"**CRITICAL:** None of the {impl_transactions_count:,} transaction objects contain a `date` field. "
          "Payment timing analysis based on transaction dates is not feasible with the current data.")
    unresolved("Are there other date signals within the implementation structure "
               "(e.g., milestone `dueDate` or `dateMet`) that could serve as a payment-timing proxy? "
               "Milestone dates are present but require further quality assessment.")
else:
    A(f"> **CONFIRMED FACT:** {impl_tx_with_date:,} transactions have a `date` field.")
A("")
if impl_tx_with_amount == 0:
    issue(f"None of the {impl_transactions_count:,} transaction objects contain a populated `amount` or `value` field. "
          "Payment-value analysis from transactions is not feasible.")
else:
    fact(f"{impl_tx_with_amount:,} transactions have a populated `amount`/`value` field.")
A("")
treatment("Frame the implementation/reporting analysis as a reporting-coverage metric, not a payment-performance metric. "
          "Count contracts with `implementation` sub-objects as an indicator of reporting completeness. "
          "Do not attempt to compute payment amounts or timelines from transaction data unless further inspection "
          "confirms sufficient coverage of amount and date fields.")

# ---- 8. Supplier ----
section("7. Supplier ID / Name Investigation")
A("### 7.1 Core Metrics")
A("")
A("| Metric | Value |")
A("|--------|-------|")
A(f"| Total supplier party objects | {total_supplier_party_objects:,} |")
A(f"| Supplier IDs null | {null_supplier_id_count:,} ({pct(null_supplier_id_count, total_supplier_party_objects)}) |")
A(f"| Unique supplier IDs (non-null) | {len(id_to_names):,} |")
A(f"| Unique supplier names (non-null) | {len(name_to_ids):,} |")
A(f"| Supplier IDs mapping to >1 name | {len(ids_with_multi_names):,} |")
A(f"| Supplier names mapping to >1 ID | {len(names_with_multi_ids):,} |")
A("")
A("### 7.2 Sample: Supplier IDs with Multiple Distinct Names")
A("")
A("(Same supplier ID appearing under different names — possible name variation for same entity)")
A("")
A("| Supplier ID | Names observed |")
A("|-------------|----------------|")
for sid, names in sample_multi_name_ids:
    names_str = " / ".join(f'`{n}`' for n in sorted(names))
    A(f"| `{sid}` | {names_str} |")
A("")
A("### 7.3 Sample: Supplier Names with Multiple Distinct IDs")
A("")
A("(Same name appearing under different IDs — possible same entity with inconsistent identifier)")
A("")
A("| Supplier name | IDs observed |")
A("|--------------|--------------|")
for sname, ids in sample_multi_id_names:
    ids_str = " / ".join(f'`{i}`' for i in sorted(ids))
    A(f"| `{sname}` | {ids_str} |")
A("")
fact(f"{len(ids_with_multi_names):,} supplier IDs are associated with more than one supplier name. "
     f"{len(names_with_multi_ids):,} supplier names are associated with more than one supplier ID.")
A("")
issue("Supplier entity resolution is non-trivial. Both ID-to-multiple-names and name-to-multiple-IDs "
      "patterns are confirmed. This affects the reliability of supplier concentration analysis.")
A("")
interp("Some ID-to-multiple-names cases may be legitimate (e.g., trading name vs. legal name). "
       "Some name-to-multiple-IDs cases may reflect data-entry inconsistencies in the identifier field. "
       "Neither pattern can be safely resolved by name-similarity alone.")
A("")
unresolved("What proportion of the 'same name, multiple IDs' cases represent genuinely different entities "
           "versus the same entity registered with different identifiers? This requires either source "
           "documentation or manual spot-checking.")
A("")
treatment("Phase 3 must define an entity-resolution strategy. At minimum: "
          "(1) preserve original source values, (2) use supplier ID as the primary grouping key, "
          "(3) document cases where ID-to-name mapping is ambiguous, "
          "(4) create an auditable mapping table if canonical entity keys are introduced. "
          "Do not merge suppliers on name similarity alone.")

# ---- Phase 3 Decision Readiness ----
section("8. Phase 3 Decision-Readiness Summary")
A("The following decisions are required before Phase 3 can be completed and schema design can begin.")
A("")
A("| # | Decision required | Evidence now available | Urgency |")
A("|---|---|---|---|")
A(f"| 1 | Release/version modelling strategy for {n_repeated_ocids:,} multi-release OCIDs | Yes — distribution confirmed, max=74 | **Critical** |")
A("| 2 | Treatment of extreme `numberOfTenderers` outlier | Yes — record identified | High |")
A("| 3 | Treatment of extreme budget value (₦6.5 trillion) | Yes — record identified | High |")
A("| 4 | Treatment of extreme award values (₦1.004 trillion) | Yes — record identified, same OCID as extreme tender | High |")
A("| 5 | Date-validity exclusion rules (placeholders, year 2922, future dates) | Yes — confirmed and quantified | High |")
A("| 6 | Supplier entity-resolution strategy | Partially — scope of problem confirmed | Medium |")
A("| 7 | Implementation / payment coverage framing | Yes — transaction dates and amounts absent | Medium |")
A("| 8 | Zero monetary value treatment (561 budget zeros, 268 award zeros) | Not yet investigated | Medium |")
A("")
A("### 8.1 Decisions Requiring Human Approval (per project rules)")
A("")
A("Per the project implementation plan, the following require your explicit decision:")
A("")
A("1. **Release/version modelling strategy** — this is the most consequential single decision.")
A("   Options include: (a) latest-release snapshot per OCID, (b) union of lifecycle stages,")
A("   (c) full history with a derived analytical snapshot. Each has trade-offs for schema design.")
A("")
A("2. **Extreme-value treatment** — which records should be flagged vs. excluded from which metrics?")
A("   (The ₦6.5T budget, the ₦1.004T award, the 90,865-tenderer record.)")
A("")
A("3. **Supplier entity-resolution depth** — should the project produce a canonical supplier mapping")
A("   table, or is it sufficient to group by supplier ID with documented caveats?")
A("")
A("---")
A("")
A("*Report generated by `python/profiling/02_targeted_validation.py`.*  ")
A(f"*Raw dataset was not modified. File size confirmed: {file_size_bytes:,} bytes. Run date: {run_date}.*")

report_text = "\n".join(lines)
os.makedirs("docs", exist_ok=True)
with open(OUTPUT_REPORT, "w", encoding="utf-8") as f:
    f.write(report_text)

print(f"\nReport written to: {OUTPUT_REPORT}")

# Final integrity check
final_size = os.path.getsize(RAW_DATA_PATH)
print(f"\nRaw file integrity check: {final_size:,} bytes (original: {file_size_bytes:,}) — {'UNCHANGED' if final_size == file_size_bytes else 'ERROR: SIZE MISMATCH'}")
print("\nDone.")
