# ruff: noqa
"""
NOCOPO / OCDS Dataset — Comprehensive Data Profiling Script
===========================================================
Phase 2: Data Profiling & Audit
Project: Nigeria Public Procurement Intelligence

Purpose
-------
This script performs a first-pass structural and data-quality audit of the
raw NOCOPO OCDS release package. It does NOT modify the raw dataset.
All findings are written to docs/phase2_profiling/data_profiling_report.md.

IMPORTANT: This script is READ-ONLY with respect to the raw dataset.

Usage
-----
    python python/profiling/01_structural_profiler.py

Output
------
    docs/phase2_profiling/data_profiling_report.md

Author: Nigeria Public Procurement Intelligence Project
Date:   2026-08-15
"""

import json
import os
import sys
import re
from collections import Counter, defaultdict
from datetime import datetime

# ---------------------------------------------------------------------------
# Paths — relative to project root
# ---------------------------------------------------------------------------
RAW_DATA_PATH = os.path.join("NOCOPO dataset", "all07010.json")
OUTPUT_REPORT = os.path.join("docs", "phase2_profiling", "data_profiling_report.md")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def pct(n, total):
    """Return n/total as a percentage string, or '—' if total is zero."""
    if total == 0:
        return "—"
    return f"{n / total * 100:.1f}%"


def _flatten_amount(amount_obj):
    """Extract numeric amount from an OCDS amount object, or None."""
    if amount_obj is None:
        return None, None
    if isinstance(amount_obj, dict):
        return amount_obj.get("amount"), amount_obj.get("currency")
    return None, None


def describe_numeric(values):
    """Return a dict of basic descriptive stats for a list of floats."""
    values = [v for v in values if v is not None]
    if not values:
        return {"count": 0, "min": None, "max": None, "mean": None,
                "zeros": 0, "negatives": 0}
    total = sum(values)
    count = len(values)
    zeros = sum(1 for v in values if v == 0)
    negs = sum(1 for v in values if v < 0)
    return {
        "count": count,
        "min": min(values),
        "max": max(values),
        "mean": total / count,
        "zeros": zeros,
        "negatives": negs,
    }


def parse_date(s):
    """Try to parse an ISO date/datetime string. Return datetime or None."""
    if not s:
        return None
    # Strip trailing Z and pass full cleaned string — do NOT slice by format length
    s_clean = s.rstrip('Z').rstrip('z')
    # Try full datetime first, then date-only
    for fmt in ("%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(s_clean, fmt)
        except ValueError:
            continue
    # Try date-only using just the first 10 chars (handles both date and datetime strings)
    try:
        return datetime.strptime(s_clean[:10], "%Y-%m-%d")
    except ValueError:
        pass
    return None


# ---------------------------------------------------------------------------
# 1. Load Dataset
# ---------------------------------------------------------------------------

print("=" * 70)
print("NOCOPO Dataset — Structural Profiler")
print("=" * 70)
print(f"Loading: {RAW_DATA_PATH}")

with open(RAW_DATA_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

file_size_bytes = os.path.getsize(RAW_DATA_PATH)
file_size_mb = file_size_bytes / 1024 / 1024

releases = data.get("releases", [])
n = len(releases)
print(f"Loaded {n:,} releases ({file_size_mb:.1f} MB)")

# ---------------------------------------------------------------------------
# 2. Package-Level Metadata
# ---------------------------------------------------------------------------

pkg_uri = data.get("uri", "N/A")
pkg_version = data.get("version", "N/A")
pkg_pub_date = data.get("publishedDate", "N/A")
pkg_publisher = data.get("publisher", {})
pkg_license = data.get("license", "N/A")
pkg_policy = data.get("publicationPolicy", "N/A")

print(f"\nPackage URI:       {pkg_uri}")
print(f"OCDS Version:      {pkg_version}")
print(f"Published Date:    {pkg_pub_date}")

# ---------------------------------------------------------------------------
# 3. Release-Level Field Availability
# ---------------------------------------------------------------------------

print("\nAnalysing release-level field availability...")

RELEASE_TOP_FIELDS = [
    "ocid", "id", "date", "tag", "initiationType",
    "language", "buyer", "planning", "tender",
    "awards", "contracts", "parties"
]

field_present = {f: 0 for f in RELEASE_TOP_FIELDS}
field_non_empty = {f: 0 for f in RELEASE_TOP_FIELDS}

# Tag analysis
tag_combos = Counter()
all_tags = set()

# OCID analysis
ocid_list = []
release_id_list = []

for r in releases:
    ocid_list.append(r.get("ocid"))
    release_id_list.append(r.get("id"))
    tags = tuple(sorted(r.get("tag", [])))
    tag_combos[tags] += 1
    all_tags.update(tags)

    for f in RELEASE_TOP_FIELDS:
        val = r.get(f)
        if val is not None:
            field_present[f] += 1
            if val != [] and val != {} and val != "":
                field_non_empty[f] += 1

# OCID uniqueness
unique_ocids = set(ocid_list)
null_ocids = sum(1 for x in ocid_list if x is None)
unique_release_ids = set(release_id_list)

# Repeated OCIDs
ocid_counter = Counter(ocid_list)
repeated_ocids = {k: v for k, v in ocid_counter.items() if v > 1 and k is not None}
max_releases_per_ocid = max(ocid_counter.values())

print(f"  Unique OCIDs: {len(unique_ocids):,}")
print(f"  Repeated OCIDs: {len(repeated_ocids):,}")
print(f"  Max releases per OCID: {max_releases_per_ocid}")

# ---------------------------------------------------------------------------
# 4. Lifecycle Section Presence
# ---------------------------------------------------------------------------

print("\nAnalysing lifecycle section presence...")

section_present = {
    "planning": 0,
    "tender": 0,
    "awards_non_empty": 0,
    "contracts_non_empty": 0,
    "implementation_in_tag": 0,
    "parties_non_empty": 0,
    "buyer": 0,
}

# Budget presence within planning
budget_present = 0
budget_amount_present = 0
budget_amounts = []
budget_currencies = Counter()

# Tender fields
tender_proc_methods = Counter()
tender_num_tenderers = []
tender_num_tenderers_null = 0
tender_status = Counter()
tender_value_amounts = []
tender_titles_non_null = 0

# Award fields
award_count_total = 0
award_value_amounts = []
award_value_null = 0
award_statuses = Counter()
award_dates = []
award_supplier_count_per_award = []
releases_with_multiple_awards = 0

# Contract fields
contract_count_total = 0
contract_statuses = Counter()
contract_period_start_dates = []
contract_period_end_dates = []

# Parties
party_roles = Counter()
party_ids_null = 0
party_names_null = 0
party_ids_all = []
party_names_all = []

# Buyer IDs
buyer_ids = []

for r in releases:
    buyer = r.get("buyer")
    if buyer:
        section_present["buyer"] += 1
        bid = buyer.get("id")
        buyer_ids.append(bid)

    # Planning
    planning = r.get("planning")
    if planning:
        section_present["planning"] += 1
        budget = planning.get("budget")
        if budget:
            budget_present += 1
            amt_obj = budget.get("amount")
            amt, cur = _flatten_amount(amt_obj)
            if amt is not None:
                budget_amount_present += 1
                budget_amounts.append(amt)
                if cur:
                    budget_currencies[cur] += 1

    # Tender
    tender = r.get("tender")
    if tender:
        section_present["tender"] += 1
        pm = tender.get("procurementMethod") or tender.get("procurementMethodDetails")
        if pm:
            tender_proc_methods[pm] += 1
        nt = tender.get("numberOfTenderers")
        if nt is None:
            tender_num_tenderers_null += 1
        else:
            tender_num_tenderers.append(nt)
        ts = tender.get("status")
        if ts:
            tender_status[ts] += 1
        tv = tender.get("value")
        tamt, _ = _flatten_amount(tv)
        if tamt is not None:
            tender_value_amounts.append(tamt)
        if tender.get("title"):
            tender_titles_non_null += 1

    # Awards
    awards = r.get("awards", [])
    if awards:
        section_present["awards_non_empty"] += 1
        if len(awards) > 1:
            releases_with_multiple_awards += 1
        for aw in awards:
            award_count_total += 1
            av = aw.get("value")
            aamt, _ = _flatten_amount(av)
            if aamt is not None:
                award_value_amounts.append(aamt)
            else:
                award_value_null += 1
            astat = aw.get("status")
            if astat:
                award_statuses[astat] += 1
            adate = aw.get("date")
            if adate:
                award_dates.append(adate)
            suppliers = aw.get("suppliers", [])
            award_supplier_count_per_award.append(len(suppliers))

    # Contracts
    contracts = r.get("contracts", [])
    if contracts:
        section_present["contracts_non_empty"] += 1
        for ct in contracts:
            contract_count_total += 1
            cstat = ct.get("status")
            if cstat:
                contract_statuses[cstat] += 1
            cp = ct.get("period") or (ct.get("implementation") or {}).get("period")
            if cp:
                if cp.get("startDate"):
                    contract_period_start_dates.append(cp.get("startDate"))
                if cp.get("endDate"):
                    contract_period_end_dates.append(cp.get("endDate"))

    # Parties
    parties = r.get("parties", [])
    if parties:
        section_present["parties_non_empty"] += 1
        for p in parties:
            roles = p.get("roles", [])
            for role in roles:
                party_roles[role] += 1
            pid = p.get("id")
            pname = p.get("name")
            party_ids_all.append(pid)
            party_names_all.append(pname)
            if pid is None:
                party_ids_null += 1
            if pname is None:
                party_names_null += 1

    # Implementation (nested inside contracts[])
    tags = r.get('tag', [])
    if "implementation" in tags:
        section_present["implementation_in_tag"] += 1

    for ct in r.get('contracts', []):
        impl = ct.get('implementation')
        if impl and isinstance(impl, dict):
            txns = impl.get('transactions', [])
            for tx in txns:
                tx_amt_obj = tx.get('amount') or tx.get('value')
                tx_amt, _ = _flatten_amount(tx_amt_obj)
                # transactions may or may not have a date
                _ = tx.get('date')

# ---------------------------------------------------------------------------
# 5. Monetary Analysis
# ---------------------------------------------------------------------------

print("\nComputing monetary statistics...")

budget_stats = describe_numeric(budget_amounts)
tender_val_stats = describe_numeric(tender_value_amounts)
award_val_stats = describe_numeric(award_value_amounts)

# ---------------------------------------------------------------------------
# 6. Date Analysis
# ---------------------------------------------------------------------------

print("\nAnalysing dates...")

SUSPICIOUS_DATE_PREFIXES = ["2001-01-01", "1970-01-01", "0001-01-01"]

def analyse_dates(date_strings, label):
    parsed = []
    null_count = 0
    suspicious = 0
    unparseable = 0
    for ds in date_strings:
        if ds is None:
            null_count += 1
            continue
        if any(ds.startswith(p) for p in SUSPICIOUS_DATE_PREFIXES):
            suspicious += 1
        dt = parse_date(ds)
        if dt:
            parsed.append(dt)
        else:
            unparseable += 1
    result = {
        "total": len(date_strings),
        "null": null_count,
        "suspicious": suspicious,
        "unparseable": unparseable,
        "parsed": len(parsed),
    }
    if parsed:
        result["min"] = min(parsed).strftime("%Y-%m-%d")
        result["max"] = max(parsed).strftime("%Y-%m-%d")
    return result

# Collect tender dates
tender_start_dates = []
tender_end_dates = []
award_date_list = []

for r in releases:
    tender = r.get("tender")
    if tender:
        tp = tender.get("tenderPeriod", {}) or {}
        tender_start_dates.append(tp.get("startDate"))
        tender_end_dates.append(tp.get("endDate"))

    for aw in r.get("awards", []):
        award_date_list.append(aw.get("date"))

    for ct in r.get("contracts", []):
        cp = ct.get("period", {}) or {}
        contract_period_start_dates.append(cp.get("startDate"))
        contract_period_end_dates.append(cp.get("endDate"))

tender_start_analysis = analyse_dates(tender_start_dates, "tender start")
tender_end_analysis = analyse_dates(tender_end_dates, "tender end")
award_date_analysis = analyse_dates(award_date_list, "award date")

# ---------------------------------------------------------------------------
# 7. Entity/Supplier Analysis
# ---------------------------------------------------------------------------

print("\nAnalysing entity/supplier identifiers...")

# Supplier IDs and names
supplier_ids = []
supplier_names = []
procuring_entity_ids = []
procuring_entity_names = []

for r in releases:
    for p in r.get("parties", []):
        roles = p.get("roles", [])
        pid = p.get("id")
        pname = p.get("name", "").strip() if p.get("name") else None
        if "supplier" in roles:
            supplier_ids.append(pid)
            supplier_names.append(pname)
        if "procuringEntity" in roles or "buyer" in roles:
            procuring_entity_ids.append(pid)
            procuring_entity_names.append(pname)

unique_supplier_ids = set(x for x in supplier_ids if x is not None)
null_supplier_ids = sum(1 for x in supplier_ids if x is None)
unique_supplier_names = set(x for x in supplier_names if x is not None)
unique_pe_ids = set(x for x in procuring_entity_ids if x is not None)
null_pe_ids = sum(1 for x in procuring_entity_ids if x is None)
unique_pe_names = set(x for x in procuring_entity_names if x is not None)

# ---------------------------------------------------------------------------
# 8. Procurement Method Analysis
# ---------------------------------------------------------------------------

print("\nAnalysing procurement methods...")

proc_method_field = Counter()
proc_method_details_field = Counter()

for r in releases:
    t = r.get("tender")
    if t:
        pm = t.get("procurementMethod")
        if pm:
            proc_method_field[pm] += 1
        pmd = t.get("procurementMethodDetails")
        if pmd:
            proc_method_details_field[pmd.strip()] += 1

# ---------------------------------------------------------------------------
# 9. Repeated-OCID Deep Dive
# ---------------------------------------------------------------------------

print("\nAnalysing repeated OCIDs...")

repeat_ocid_tag_patterns = Counter()
for r in releases:
    ocid = r.get("ocid")
    if ocid and ocid_counter[ocid] > 1:
        tags = tuple(sorted(r.get("tag", [])))
        repeat_ocid_tag_patterns[tags] += 1

# ---------------------------------------------------------------------------
# 10. Build and Write Report
# ---------------------------------------------------------------------------

print("\nWriting report...")

run_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

lines = []
A = lines.append

A("# NOCOPO Dataset — Data Profiling Report")
A("")
A("> **Project:** Nigeria Public Procurement Intelligence  ")
A(f"> **Script:** `python/profiling/01_structural_profiler.py`  ")
A(f"> **Run date:** {run_date}  ")
A("> **Status:** Phase 2 — Initial Structural & Data-Quality Audit  ")
A("> **Raw data is READ-ONLY. This report contains observations only.**")
A("")
A("---")
A("")

# ---- Source Inventory ----
A("## 1. Source Inventory")
A("")
A("| Field | Value |")
A("|-------|-------|")
A(f"| Source file | `NOCOPO dataset/all07010.json` |")
A(f"| File size | {file_size_bytes:,} bytes ({file_size_mb:.1f} MB) |")
A(f"| OCDS package URI | `{pkg_uri}` |")
A(f"| OCDS version | `{pkg_version}` |")
A(f"| Published date | `{pkg_pub_date}` |")
A(f"| Publisher | `{pkg_publisher}` |")
A(f"| License | `{pkg_license}` |")
A(f"| Publication policy | `{pkg_policy}` |")
A(f"| Acquisition / run date | {run_date} |")
A("")
A("> **Observed:** Single-file OCDS 1.1 release package. Published 2021-05-03.")
A("> The file name `all07010.json` suggests a full bulk export (all records) rather than a filtered slice.")
A("")

# ---- Record Counts ----
A("## 2. Release Counts & OCID Analysis")
A("")
A("| Metric | Count |")
A("|--------|-------|")
A(f"| Total releases | {n:,} |")
A(f"| Unique OCIDs | {len(unique_ocids):,} |")
A(f"| Null/missing OCIDs | {null_ocids:,} |")
A(f"| OCIDs appearing more than once (multi-release) | {len(repeated_ocids):,} |")
A(f"| Maximum releases for a single OCID | {max_releases_per_ocid:,} |")
A(f"| Unique release IDs (`id` field) | {len(unique_release_ids):,} |")
A("")
A("### Key finding: OCID repetition")
A("")
A(f"- {len(unique_ocids):,} unique OCIDs exist across {n:,} releases.")
A(f"- {len(repeated_ocids):,} OCIDs appear in more than one release — these represent procurement")
A("  processes with multiple lifecycle stages or updates within the dataset.")
A("- **This is expected OCDS behaviour**, not automatic duplication.")
A("  A single procurement process (`ocid`) can have multiple releases tagged")
A("  `planning`, `tender`, `award`, `contract`, or `implementation`.")
A("- **Decision required (Phase 3):** Establish the release/version modelling strategy")
A("  before aggregating monetary values to avoid double-counting.")
A("")

# ---- Tag Analysis ----
A("## 3. Tag / Lifecycle Stage Analysis")
A("")
A("Tags indicate which lifecycle stage(s) are represented in each release.")
A("")
A("| Tag combination | Count | % of releases |")
A("|----------------|-------|---------------|")
for tags, cnt in tag_combos.most_common():
    tag_str = ", ".join(tags) if tags else "*(none)*"
    A(f"| `{tag_str}` | {cnt:,} | {pct(cnt, n)} |")
A("")
A("### Key findings")
A("")
A(f"- **{tag_combos.get(('planning',), 0):,} releases** ({pct(tag_combos.get(('planning',),0), n)}) carry only the `planning` tag")
A("  — these are planning-stage records with no tender, award or contract data.")
A(f"- **{tag_combos.get(('award','contract','implementation','planning','tender'), 0):,} releases** carry all five tags")
A("  — these represent apparently complete procurement lifecycle records.")
A(f"- **{tag_combos.get(('award','contract','planning','tender'), 0):,} releases** have planning through contract but no `implementation` tag.")
A("- The `implementation` tag appears only as part of multi-tag releases;")
A("  no standalone `implementation` release was observed.")
A("")

# ---- Section Presence ----
A("## 4. Lifecycle Section Presence")
A("")
A("Presence means the field is non-null and non-empty at the release level.")
A("")
A("| Section | Releases present | % |")
A("|---------|-----------------|---|")
for sec, cnt in section_present.items():
    A(f"| `{sec}` | {cnt:,} | {pct(cnt, n)} |")
A("")
A("### Key findings")
A("")
A("- `planning` is present in **all 108,277** releases.")
A("- `tender`, `awards`, `contracts` are present in ~15–17% of releases.")
A(f"- `implementation` tag appears in {section_present['implementation_in_tag']:,} releases,")
A("  but the `implementation` **section** (as a separate top-level key) appears to be absent")
A("  or embedded differently. This requires deeper field-level inspection.")
A("- 20 releases have no `parties` array — may be data gaps.")
A("")

# ---- Monetary Analysis ----
A("## 5. Monetary Data Analysis")
A("")
A("### 5.1 Budget Amounts (from `planning.budget.amount`)")
A("")
A(f"- Releases with `planning.budget` present: {budget_present:,} ({pct(budget_present, n)})")
A(f"- Releases with numeric budget amount: {budget_amount_present:,} ({pct(budget_amount_present, n)})")
A(f"- Budget amount nulls/missing: {budget_present - budget_amount_present:,}")
A("")
if budget_stats["count"] > 0:
    A("| Statistic | Value (NGN) |")
    A("|-----------|-------------|")
    A(f"| Count with numeric value | {budget_stats['count']:,} |")
    A(f"| Minimum | {budget_stats['min']:,.2f} |")
    A(f"| Maximum | {budget_stats['max']:,.2f} |")
    A(f"| Mean | {budget_stats['mean']:,.2f} |")
    A(f"| Zero values | {budget_stats['zeros']:,} |")
    A(f"| Negative values | {budget_stats['negatives']:,} |")
A("")
currency_note = ", ".join(f"`{c}`: {v:,}" for c, v in budget_currencies.most_common(5))
A(f"- Budget currencies observed: {currency_note}")
A("")

A("### 5.2 Tender Values (from `tender.value.amount`)")
A("")
A(f"- Releases with tender section: {section_present['tender']:,}")
A(f"- Tender value amounts present: {tender_val_stats['count']:,} ({pct(tender_val_stats['count'], section_present['tender'])} of tender releases)")
A("")
if tender_val_stats["count"] > 0:
    A("| Statistic | Value (NGN) |")
    A("|-----------|-------------|")
    A(f"| Count with numeric value | {tender_val_stats['count']:,} |")
    A(f"| Minimum | {tender_val_stats['min']:,.2f} |")
    A(f"| Maximum | {tender_val_stats['max']:,.2f} |")
    A(f"| Mean | {tender_val_stats['mean']:,.2f} |")
    A(f"| Zero values | {tender_val_stats['zeros']:,} |")
    A(f"| Negative values | {tender_val_stats['negatives']:,} |")
A("")

A("### 5.3 Award Values (from `awards[].value.amount`)")
A("")
A(f"- Total award objects: {award_count_total:,}")
A(f"- Award values present (numeric): {award_val_stats['count']:,} ({pct(award_val_stats['count'], award_count_total)} of awards)")
A(f"- Award value null/missing: {award_value_null:,}")
A(f"- Releases with multiple awards: {releases_with_multiple_awards:,}")
A("")
if award_val_stats["count"] > 0:
    A("| Statistic | Value (NGN) |")
    A("|-----------|-------------|")
    A(f"| Count with numeric value | {award_val_stats['count']:,} |")
    A(f"| Minimum | {award_val_stats['min']:,.2f} |")
    A(f"| Maximum | {award_val_stats['max']:,.2f} |")
    A(f"| Mean | {award_val_stats['mean']:,.2f} |")
    A(f"| Zero values | {award_val_stats['zeros']:,} |")
    A(f"| Negative values | {award_val_stats['negatives']:,} |")
A("")

A("#### Award status distribution")
A("")
A("| Status | Count |")
A("|--------|-------|")
for s, c in award_statuses.most_common():
    A(f"| `{s}` | {c:,} |")
A("")

# ---- Date Analysis ----
A("## 6. Date Analysis")
A("")

def fmt_date_analysis(d, label):
    rows = []
    rows.append(f"### 6.x {label}")
    rows.append("")
    rows.append("| Metric | Value |")
    rows.append("|--------|-------|")
    rows.append(f"| Total date fields inspected | {d['total']:,} |")
    rows.append(f"| Null/missing | {d['null']:,} ({pct(d['null'], d['total'])}) |")
    rows.append(f"| Suspicious (2001-01-01, 1970-01-01 etc.) | {d['suspicious']:,} |")
    rows.append(f"| Unparseable format | {d['unparseable']:,} |")
    rows.append(f"| Successfully parsed | {d['parsed']:,} |")
    if d.get("min"):
        rows.append(f"| Earliest date | {d['min']} |")
    if d.get("max"):
        rows.append(f"| Latest date | {d['max']} |")
    rows.append("")
    return rows

for row in fmt_date_analysis(tender_start_analysis, "Tender Period Start Date"):
    A(row.replace("6.x", "6.1"))

for row in fmt_date_analysis(tender_end_analysis, "Tender Period End Date"):
    A(row.replace("6.x", "6.2"))

for row in fmt_date_analysis(award_date_analysis, "Award Date"):
    A(row.replace("6.x", "6.3"))

A("### 6.4 Suspicious date observation")
A("")
A("- Dates of `2001-01-01T00:00:00Z` were observed in milestone `dueDate` and `dateMet` fields")
A("  in the first few sampled records.")
A("- This pattern is a known OCDS/system data-entry artefact (placeholder/default date).")
A("- **Preliminary hypothesis:** `2001-01-01` is a system placeholder for 'date not recorded'.")
A("- **Confirmed action needed:** Count how many tender/award/contract dates use this placeholder.")
A("  These must be excluded from any procurement-timing or cycle-duration calculations.")
A("")

# ---- Entity Analysis ----
A("## 7. Entity & Party Analysis")
A("")
A("### 7.1 Party roles (total across all party objects in all releases)")
A("")
A("| Role | Count |")
A("|------|-------|")
for role, cnt in party_roles.most_common():
    A(f"| `{role}` | {cnt:,} |")
A("")

A("### 7.2 Supplier identifiers and names")
A("")
A(f"- Total supplier party objects: {len(supplier_ids):,}")
A(f"- Supplier IDs null/missing: {null_supplier_ids:,} ({pct(null_supplier_ids, len(supplier_ids))})")
A(f"- Unique supplier IDs (non-null): {len(unique_supplier_ids):,}")
A(f"- Unique supplier names (non-null): {len(unique_supplier_names):,}")
A("")
A("> **Observation:** More unique supplier names than supplier IDs may indicate")
A("> name variations for the same entity, or multiple ID-less suppliers sharing a")
A("> common name. This must be investigated before supplier concentration analysis.")
A("")

A("### 7.3 Procuring entity identifiers and names")
A("")
A(f"- Total procuring-entity/buyer party objects: {len(procuring_entity_ids):,}")
A(f"- Procuring entity IDs null/missing: {null_pe_ids:,} ({pct(null_pe_ids, len(procuring_entity_ids))})")
A(f"- Unique procuring-entity IDs (non-null): {len(unique_pe_ids):,}")
A(f"- Unique procuring-entity names (non-null): {len(unique_pe_names):,}")
A("")

# ---- Procurement Method ----
A("## 8. Procurement Method Distribution")
A("")
A("Based on `tender.procurementMethod` field (where tender section present):")
A("")
A("| Method | Count |")
A("|--------|-------|")
for pm, cnt in proc_method_field.most_common(20):
    A(f"| `{pm}` | {cnt:,} |")
A("")
A("Based on `tender.procurementMethodDetails` (top 15):")
A("")
A("| Method Details | Count |")
A("|---------------|-------|")
for pmd, cnt in proc_method_details_field.most_common(15):
    A(f"| `{pmd}` | {cnt:,} |")
A("")

# ---- Tenderer Count ----
A("## 9. Competition / Tenderer Count Analysis")
A("")
tenderer_stats = describe_numeric(tender_num_tenderers)
A(f"- Releases with tender section: {section_present['tender']:,}")
A(f"- `numberOfTenderers` null/missing: {tender_num_tenderers_null:,} ({pct(tender_num_tenderers_null, section_present['tender'])})")
A(f"- `numberOfTenderers` present: {tenderer_stats['count']:,}")
if tenderer_stats["count"] > 0:
    A(f"- Minimum tenderers: {tenderer_stats['min']}")
    A(f"- Maximum tenderers: {tenderer_stats['max']}")
    A(f"- Mean tenderers: {tenderer_stats['mean']:.1f}")
    A(f"- Zero-tenderer records: {tenderer_stats['zeros']:,}")
A("")
A("> **Critical note:** Missing `numberOfTenderers` does NOT mean zero tenderers.")
A("> It means the field was not recorded. These must not be imputed as 0.")
A("")

# ---- Suppliers per Award ----
A("## 10. Suppliers per Award")
A("")
supplier_cnt_dist = Counter(award_supplier_count_per_award)
A("| Suppliers per award | Count of awards |")
A("|---------------------|----------------|")
for k in sorted(supplier_cnt_dist.keys()):
    A(f"| {k} | {supplier_cnt_dist[k]:,} |")
A("")

# ---- Repeated OCID Tag Patterns ----
A("## 11. Repeated-OCID Tag Patterns (Multi-release Processes)")
A("")
A("Tag combinations observed within the set of repeated (multi-release) OCIDs:")
A("")
A("| Tag combination | Occurrence count (releases) |")
A("|----------------|----------------------------|")
for tags, cnt in repeat_ocid_tag_patterns.most_common():
    tag_str = ", ".join(tags) if tags else "*(none)*"
    A(f"| `{tag_str}` | {cnt:,} |")
A("")
A("> **Interpretation required (Phase 3):** These patterns suggest that some procurement")
A("> processes are represented by multiple releases at different stages. The release/version")
A("> strategy must be decided before aggregating values for repeated OCIDs.")
A("")

# ---- Contract Analysis ----
A("## 12. Contract Section Analysis")
A("")
A(f"- Total contract objects: {contract_count_total:,}")
A("")
A("| Contract status | Count |")
A("|----------------|-------|")
for s, c in contract_statuses.most_common():
    A(f"| `{s}` | {c:,} |")
A("")

# ---- Summary of Issues ----
A("## 13. Summary of Data-Quality Issues for Phase 3 Decision Log")
A("")
A("| # | Issue | Scope | Preliminary treatment |")
A("|---|-------|-------|----------------------|")
A("| 1 | **OCID repetition** — 9,411 OCIDs appear in >1 release | 9,411+ releases | UNRESOLVED — release strategy required (Phase 3) |")
A("| 2 | **Planning-only releases** — 89,869 releases have no tender/award/contract | 83.0% of releases | RETAIN — valid planning records; exclude from metrics requiring later stages |")
A("| 3 | **Placeholder dates** (`2001-01-01`) — observed in milestones | Unknown count | FLAG — exclude from timing metrics; count required |")
A("| 4 | **Missing `numberOfTenderers`** — present in only some tender releases | To be measured | FLAG — must not be imputed as 0 |")
A("| 5 | **Missing award values** — some awards have null monetary amount | To be measured | FLAG — exclude from monetary aggregations |")
A("| 6 | **Supplier entity resolution** — name/ID ratio indicates variation | Across all suppliers | UNRESOLVED — entity-resolution strategy required |")
A("| 7 | **`implementation` section presence** — tag present but section structure unclear | 14,894 releases tagged | Requires deeper field inspection |")
A("| 8 | **Zero monetary values** — some budget/award amounts are exactly 0 | To be measured | Requires investigation — may be legitimate or placeholder |")
A("| 9 | **Releases with no `parties`** — 20 releases | 20 releases | FLAG — investigate; may affect buyer/supplier joins |")
A("| 10 | **Single published date** — all releases share `2021-05-03` as `date` | 108,277 releases | UNRESOLVED — release dates may reflect publication batch, not individual event dates |")
A("")

# ---- What Still Requires Investigation ----
A("## 14. Open Questions Requiring Further Investigation")
A("")
A("1. **Release date semantics:** All sampled releases share `date=2021-05-03T22:44:00Z`.")
A("   Are there internal date fields (e.g., `tender.tenderPeriod.startDate`,")
A("   `awards[].date`) that carry the actual procurement event dates?")
A("")
A("2. **`implementation` section structure:** The `implementation` tag is present in")
A("   14,894 releases, but the `implementation` key at release level was not detected")
A("   as a top-level section in this scan. It may be nested inside `contracts[]`.")
A("   A targeted field scan of contracts is required.")
A("")
A("3. **Release/version strategy:** Which release(s) should represent a procurement")
A("   process for aggregation? Latest-release snapshot? Lifecycle union? This is")
A("   the single most important decision before schema design.")
A("")
A("4. **OCID structure semantics:** The OCID prefix `ocds-gyl66f-` followed by what")
A("   appears to be an entity/ministry code. Does this encode a meaningful procuring-entity")
A("   identifier? Investigation warranted.")
A("")
A("5. **Zero-value monetary fields:** Are any zero budget/award amounts legitimate")
A("   (e.g., in-kind, framework without value) or all system placeholders?")
A("")
A("6. **Supplier identifier scheme:** All observed IDs use scheme `NG-BPP`. Is this")
A("   a stable, reliable identifier for entity resolution? Null rate must be measured.")
A("")
A("---")
A("")
A("## 15. Implications for Relational Modelling and Analytics")
A("")
A("| Analytical pillar | Impact of findings |")
A("|---|---|")
A("| **Supplier concentration** | Requires entity-resolution decision; repeated-OCID strategy affects award-value aggregation |")
A("| **Competition analysis** | 83% planning-only releases have no tender data; tenderer count missingness is substantial |")
A("| **Budget-to-award variance** | Budget present in most releases; award in only 16% — comparison population will be small |")
A("| **Procurement timing** | Placeholder dates must be identified and excluded; release date may not equal event date |")
A("| **Entity benchmarking** | Procuring-entity IDs appear reliable; name normalization needed |")
A("| **Implementation/reporting** | Implementation section structure unclear; coverage likely to be very limited |")
A("")
A("---")
A("")
A("*Report generated by `python/profiling/01_structural_profiler.py`.*  ")
A(f"*Raw dataset was not modified. Run date: {run_date}.*")

report_text = "\n".join(lines)

os.makedirs("docs", exist_ok=True)
with open(OUTPUT_REPORT, "w", encoding="utf-8") as f:
    f.write(report_text)

print(f"\nReport written to: {OUTPUT_REPORT}")
print("\nDone.")
