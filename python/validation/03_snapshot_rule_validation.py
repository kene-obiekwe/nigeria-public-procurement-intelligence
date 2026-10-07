"""
NOCOPO / OCDS Dataset — Process-Snapshot Rule Validation
========================================================
Phase 4.1: Relational design review
Project: Nigeria Public Procurement Intelligence

Purpose
-------
Test the Phase 4 process-snapshot rule ("one release per OCID: prefer the
release with the most lifecycle tags, tie-break on highest release_id")
against the raw data, and measure the evidence needed to close the Phase 4
open issues (17.1–17.4).

Investigations
--------------
1. release_id format and text-vs-integer ordering of the tie-break
2. Content divergence between releases of the same OCID
   (budget amount, projectID, tag set, award value/supplier)
3. Candidate snapshot rules compared on planned budget (M-P01)
4. Lifecycle-section alignment across releases (tender / award / contract)
5. Open-issue probes: tender.id uniqueness (17.4), milestone date quality
   (17.2), implementation transaction value patterns (17.1 / DQ-12)

IMPORTANT: This script is READ-ONLY with respect to the raw dataset.

Usage
-----
    python python/validation/03_snapshot_rule_validation.py

Output
------
    docs/phase4_1_snapshot_validation_report.md
"""

import hashlib
import json
import os
import sys
from collections import Counter, defaultdict
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, "NOCOPO dataset", "all07010.json")
OUTPUT = os.path.join(ROOT, "docs", "phase4_1_snapshot_validation_report.md")

EXTREME_BUDGET = 1e12          # DQ-06 threshold (NGN 1 trillion)
PLACEHOLDER_DATE = "2001-01-01"  # DQ-08
FULL_LIFECYCLE = ("award", "contract", "implementation", "planning", "tender")


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def rid(r):
    return int(r["id"])


def tags(r):
    return tuple(sorted(r.get("tag", [])))


def budget(r):
    return (r.get("planning") or {}).get("budget")


def budget_amount(r):
    b = budget(r)
    return (b.get("amount") or {}).get("amount") if b else None


def project_id(r):
    b = budget(r)
    return b.get("projectID") if b else None


def award_signature(r):
    a = r["awards"][0]
    return (
        (a.get("value") or {}).get("amount"),
        tuple(sorted(s.get("id", "") for s in a.get("suppliers", []))),
    )


def latest_with(releases, key):
    """Highest integer release_id among releases containing a non-empty section."""
    w = [r for r in releases if r.get(key)]
    return max(w, key=rid) if w else None


def classify_date(value):
    """Phase 3 date classes (DQ-08/09). Returns None for null."""
    if not value:
        return None
    try:
        year = int(value[:4])
    except ValueError:
        return "UNPARSEABLE"
    if value.startswith(PLACEHOLDER_DATE):
        return "PLACEHOLDER"
    if year > 2050:
        return "IMPOSSIBLE"
    if year >= 2026:
        return "FUTURE"
    return "VALID"


def bn(x):
    return f"{x / 1e9:,.1f}"


def sum_budget(values):
    """Sum budget values excluding NULL and DQ-06 EXTREME (>= NGN 1T)."""
    return sum(v for v in values if v is not None and v < EXTREME_BUDGET)


# ------------------------------------------------------------------
# Snapshot rule candidates — each returns the budget used for one OCID
# ------------------------------------------------------------------
def rule_r0_text(releases):
    """Phase 4 v1.0 as written: most tags, tie-break on release_id as TEXT."""
    return budget_amount(max(releases, key=lambda r: (len(r["tag"]), r["id"])))


def rule_r1_integer(releases):
    """Phase 4 v1.0 with integer tie-break."""
    return budget_amount(max(releases, key=lambda r: (len(r["tag"]), rid(r))))


def rule_r2_section(releases):
    """Section-level: latest release (integer id) that contains a budget."""
    w = [r for r in releases if budget(r)]
    return budget_amount(max(w, key=rid)) if w else None


def rule_r3_section_per_project(releases):
    """Section-level per (OCID, projectID): latest budget per project, summed."""
    per_project = {}
    for r in sorted((r for r in releases if budget(r)), key=rid):
        per_project[project_id(r)] = budget_amount(r)
    return sum(v for v in per_project.values() if v is not None) if per_project else None


RULES = [
    ("R0", "Phase 4 v1.0 as written (most tags; text tie-break)", rule_r0_text),
    ("R1", "Most tags; integer tie-break", rule_r1_integer),
    ("R2", "Section-level latest release with a budget (integer)", rule_r2_section),
    ("R3", "R2 per (OCID, projectID), summed", rule_r3_section_per_project),
]


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    if not os.path.exists(SOURCE):
        sys.exit(f"Source file not found: {SOURCE}")

    with open(SOURCE, "rb") as fh:
        sha256 = hashlib.sha256(fh.read()).hexdigest()
    with open(SOURCE, encoding="utf-8") as fh:
        releases = json.load(fh)["releases"]

    by_ocid = defaultdict(list)
    for r in releases:
        by_ocid[r["ocid"]].append(r)
    multi = {k: v for k, v in by_ocid.items() if len(v) > 1}

    out = []
    w = out.append

    # --- 1. Ordering --------------------------------------------------
    ids = [r["id"] for r in releases]
    all_digit = all(isinstance(i, str) and i.isdigit() for i in ids)
    order_diff = sum(
        1 for v in multi.values()
        if max(v, key=lambda r: r["id"])["id"] != max(v, key=rid)["id"]
    )

    # --- 2. Divergence ------------------------------------------------
    budget_div = {
        k: v for k, v in multi.items()
        if len({json.dumps((budget(r) or {}).get("amount"), sort_keys=True) for r in v}) > 1
    }
    div_missing_only = sum(
        1 for v in budget_div.values()
        if len({budget_amount(r) for r in v if budget(r)}) <= 1
    )
    mixed_tags = sum(1 for v in multi.values() if len({tags(r) for r in v}) > 1)
    multi_full = sum(
        1 for v in multi.values() if sum(tags(r) == FULL_LIFECYCLE for r in v) >= 2
    )
    latest_no_budget = sum(1 for v in multi.values() if not budget(max(v, key=rid)))

    pattern = {}
    for k, v in multi.items():
        pids = {project_id(r) for r in v if budget(r)}
        amts = {budget_amount(r) for r in v if budget(r)}
        if len(pids) > 1:
            pattern[k] = "MULTI_PROJECT"
        elif len(amts) > 1:
            pattern[k] = "SAME_PROJECT_REVISED"
        else:
            pattern[k] = "IDENTICAL_BUDGET"
    pattern_counts = Counter(pattern.values())
    multi_project = [k for k, p in pattern.items() if p == "MULTI_PROJECT"]
    mp_planning_only = sum(
        1 for k in multi_project if all(tags(r) == ("planning",) for r in by_ocid[k])
    )

    pid_to_ocids = defaultdict(set)
    for r in releases:
        if budget(r):
            pid_to_ocids[project_id(r)].add(r["ocid"])
    pid_cross_ocid = sum(1 for s in pid_to_ocids.values() if len(s) > 1)

    award_multi = [v for v in multi.values() if sum(1 for r in v if r.get("awards")) > 1]
    award_conflicts = [
        v[0]["ocid"] for v in award_multi
        if len({award_signature(r) for r in v if r.get("awards")}) > 1
    ]

    # --- 3. Rule comparison -------------------------------------------
    rule_values = {code: {k: fn(v) for k, v in by_ocid.items()} for code, _, fn in RULES}
    budget_rows_r3 = sum(
        len({project_id(r) for r in v if budget(r)}) for v in by_ocid.values()
    )

    # --- 4. Section alignment -----------------------------------------
    align = Counter()
    for v in multi.values():
        t, a, c = (latest_with(v, s) for s in ("tender", "awards", "contracts"))
        if a and c and a["id"] != c["id"]:
            align["award_release_ne_contract_release"] += 1
        if t and a and t["id"] != a["id"]:
            align["tender_release_ne_award_release"] += 1
    contract_award_cross = sum(
        1 for r in releases for c in r.get("contracts", [])
        if c.get("awardID") not in {a.get("id") for a in r.get("awards", [])}
    )
    max_awards_per_release = max(len(r.get("awards", [])) for r in releases)

    # --- 5. Open-issue probes -----------------------------------------
    tender_ids = [r["tender"].get("id") for r in releases if r.get("tender")]
    tender_null = sum(1 for t in tender_ids if t in (None, ""))
    tender_dupes = sum(1 for c in Counter(tender_ids).values() if c > 1)

    ms_counts = defaultdict(Counter)
    for r in releases:
        for c in r.get("contracts", []):
            for source, items in (
                ("CONTRACT", c.get("milestones", [])),
                ("IMPLEMENTATION", (c.get("implementation") or {}).get("milestones", [])),
            ):
                for m in items:
                    ms_counts[source, "total"][None] += 1
                    ms_counts[source, "dueDate"][classify_date(m.get("dueDate"))] += 1
                    ms_counts[source, "dateMet"][classify_date(m.get("dateMet"))] += 1

    txn_per_contract = Counter()
    txn_pairs = Counter()
    txn_vs_contract = Counter()
    for r in releases:
        for c in r.get("contracts", []):
            txns = (c.get("implementation") or {}).get("transactions", [])
            txn_per_contract[len(txns)] += 1
            vals = [(t.get("value") or {}).get("amount") for t in txns]
            vals = [x for x in vals if x is not None]
            cv = (c.get("value") or {}).get("amount")
            if len(vals) == 2:
                a, b = vals
                txn_pairs["second_gt_first" if b > a else "second_eq_first" if b == a else "second_lt_first"] += 1
            if vals and cv:
                s = sum(vals)
                if abs(s - cv) < 0.01:
                    txn_vs_contract["sum_equals_contract_value"] += 1
                elif abs(max(vals) - cv) < 0.01:
                    txn_vs_contract["max_equals_contract_value"] += 1
                elif s > cv:
                    txn_vs_contract["sum_exceeds_contract_value"] += 1
                else:
                    txn_vs_contract["sum_below_contract_value"] += 1

    # ------------------------------------------------------------------
    # Report
    # ------------------------------------------------------------------
    w("# Phase 4.1 — Process-Snapshot Rule Validation Report")
    w("")
    w("> **Script:** `python/validation/03_snapshot_rule_validation.py`  ")
    w(f"> **Run date:** {datetime.now():%Y-%m-%d %H:%M:%S}  ")
    w(f"> **Source SHA-256:** `{sha256}`  ")
    w("> **Raw data is READ-ONLY. This report contains measured observations only.**")
    w("> Decisions taken on this evidence are recorded in `docs/phase4_relational_model.md` v1.1.")
    w("")
    w("## 1. Population")
    w("")
    w("| Metric | Value |")
    w("|---|---|")
    w(f"| Releases | {len(releases):,} |")
    w(f"| Unique OCIDs | {len(by_ocid):,} |")
    w(f"| Multi-release OCIDs | {len(multi):,} |")
    w(f"| Max awards per release | {max_awards_per_release} |")
    w("")
    w("## 2. Tie-break ordering (release_id)")
    w("")
    w("| Check | Result |")
    w("|---|---|")
    w(f"| release_id stored as numeric string | {all_digit} (JSON type: string) |")
    w(f"| Multi-release OCIDs where text-max ≠ integer-max release | **{order_diff:,}** of {len(multi):,} |")
    w("")
    w("> Ordering `release_id` as text (e.g. '9459' > '114592') selects a different release")
    w("> than numeric ordering. Any tie-break must cast to integer.")
    w("")
    w("## 3. Content divergence within multi-release OCIDs")
    w("")
    w("| Check | OCIDs |")
    w("|---|---|")
    w(f"| Budget object differs across releases | {len(budget_div):,} |")
    w(f"|   of which only because some releases lack a budget | {div_missing_only:,} |")
    w(f"|   of which ≥2 distinct non-null budget amounts | {len(budget_div) - div_missing_only:,} |")
    w(f"| Mixed tag sets across releases | {mixed_tags:,} |")
    w(f"| ≥2 full-lifecycle releases | {multi_full:,} |")
    w(f"| Integer-latest release has no budget | {latest_no_budget:,} |")
    w(f"| Awards in >1 release | {len(award_multi):,} |")
    w(f"|   of which award value or supplier differs | {len(award_conflicts):,} |")
    w("")
    w("### 3.1 Budget pattern classification (all multi-release OCIDs)")
    w("")
    w("| Pattern | Definition | OCIDs |")
    w("|---|---|---|")
    w(f"| IDENTICAL_BUDGET | One projectID, one budget amount | {pattern_counts['IDENTICAL_BUDGET']:,} |")
    w(f"| SAME_PROJECT_REVISED | One projectID, amount changes across releases | {pattern_counts['SAME_PROJECT_REVISED']:,} |")
    w(f"| MULTI_PROJECT | ≥2 distinct budget projectIDs under one OCID | {pattern_counts['MULTI_PROJECT']:,} |")
    w("")
    w(f"- MULTI_PROJECT OCIDs consisting solely of planning-only releases: {mp_planning_only:,} of {len(multi_project):,}")
    w(f"- Distinct budget projectIDs: {len(pid_to_ocids):,}; projectIDs spanning >1 OCID: {pid_cross_ocid:,}")
    w("")
    w("> MULTI_PROJECT OCIDs carry unrelated budget lines (different projectID, description and")
    w("> amount) under one OCID. One-release-per-OCID selection silently drops all but one.")
    w("")
    w("### 3.2 OCIDs with conflicting award content across releases")
    w("")
    for o in award_conflicts:
        w(f"- `{o}`")
    w("")
    w("> In these OCIDs the integer-latest award release carries the most recent correction")
    w("> (e.g. a ×100 value revision reverted, a placeholder supplier '1' replaced by a named supplier).")
    w("")
    w("## 4. Candidate rules compared on planned budget (M-P01 input)")
    w("")
    w("Totals exclude DQ-06 EXTREME budgets (≥ NGN 1T) and NULLs.")
    w("")
    w("| Rule | Description | OCIDs with budget | Total (NGN bn) |")
    w("|---|---|---|---|")
    for code, desc, _ in RULES:
        vals = rule_values[code]
        w(f"| {code} | {desc} | {sum(v is not None for v in vals.values()):,} | {bn(sum_budget(vals.values()))} |")
    w("")
    w("| Comparison | OCIDs whose budget differs |")
    w("|---|---|")
    for a, b in (("R0", "R1"), ("R1", "R2"), ("R2", "R3")):
        diff = sum(1 for k in by_ocid if rule_values[a][k] != rule_values[b][k])
        w(f"| {a} vs {b} | {diff:,} |")
    w("")
    w(f"- Budget rows under R3 (one per OCID × projectID): {budget_rows_r3:,}")
    w("")
    w("## 5. Lifecycle-section alignment")
    w("")
    w("| Check | Count |")
    w("|---|---|")
    w(f"| Contracts whose awardID is not in the same release | {contract_award_cross:,} |")
    w(f"| OCIDs where latest award release ≠ latest contract release | {align['award_release_ne_contract_release']:,} |")
    w(f"| OCIDs where latest tender release ≠ latest award release | {align['tender_release_ne_award_release']:,} |")
    w("")
    w("> Awards and contracts always travel together in one release, so selecting the")
    w("> award/contract section from a single release preserves the contract → award link.")
    w("")
    w("## 6. Open-issue probes")
    w("")
    w("### 6.1 tender.id uniqueness (Phase 4 §17.4)")
    w("")
    w("| Check | Result |")
    w("|---|---|")
    w(f"| Tender objects | {len(tender_ids):,} |")
    w(f"| Null/empty tender.id | {tender_null:,} |")
    w(f"| Distinct tender.id | {len(set(tender_ids)):,} |")
    w(f"| tender.id values appearing in >1 release | {tender_dupes:,} |")
    w("")
    w("### 6.2 Milestone date quality (Phase 4 §17.2)")
    w("")
    w("| Source | Field | Total | NULL | VALID | PLACEHOLDER | FUTURE | IMPOSSIBLE | UNPARSEABLE |")
    w("|---|---|---|---|---|---|---|---|---|")
    for source in ("CONTRACT", "IMPLEMENTATION"):
        total = ms_counts[source, "total"][None]
        for field in ("dueDate", "dateMet"):
            c = ms_counts[source, field]
            w(f"| {source} | {field} | {total:,} | {c[None]:,} | {c['VALID']:,} | {c['PLACEHOLDER']:,} "
              f"| {c['FUTURE']:,} | {c['IMPOSSIBLE']:,} | {c['UNPARSEABLE']:,} |")
    w("")
    w("### 6.3 Implementation transaction values (Phase 4 §17.1 / DQ-12)")
    w("")
    w("| Check | Count |")
    w("|---|---|")
    for n, c in sorted(txn_per_contract.items()):
        w(f"| Contracts with {n} transaction(s) | {c:,} |")
    for k, c in sorted(txn_pairs.items()):
        w(f"| Two-transaction contracts: {k} | {c:,} |")
    for k, c in sorted(txn_vs_contract.items()):
        w(f"| Transactions vs contract value: {k} | {c:,} |")
    w("")
    w("> Evidence only. These patterns do not by themselves establish whether transaction")
    w("> values are cumulative or incremental; DQ-12 remains UNRESOLVED.")
    w("")
    w("---")
    w("")
    w("*Generated by `python/validation/03_snapshot_rule_validation.py`. Raw dataset not modified.*")

    with open(OUTPUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out) + "\n")
    print(f"Report written: {OUTPUT}")


if __name__ == "__main__":
    main()
