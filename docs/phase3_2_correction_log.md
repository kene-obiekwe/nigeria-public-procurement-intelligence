# Phase 3.2 Correction Log
# Nigeria Public Procurement Intelligence

> **Phase:** 3.2 — Specification Correction Pass
> **Correction date:** 2026-10-07
> **Approved by:** Project owner (2026-10-07)
> **Reviewed against:** `docs/phase3_metric_eligibility.md` v1.1 (2026-08-18)
> **Evidence:** `docs/phase4_1_snapshot_validation_report.md`
> **Raw dataset:** NOT modified.

---

## Purpose

Phase 3 documentation was frozen on 2026-08-18. Changes are allowed only
through an explicitly approved correction pass. This log records one
correction. It arose from the Phase 4.1 validation of the process-snapshot
rule against the raw data.

---

## Correction C-06 — M-P01 Budget Aggregation Grain

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-06 |
| **Document** | `docs/phase3_metric_eligibility.md`: §1.3 (double-counting table), Pillar 1 (valid population, double-counting risks), M-P01 (aggregation rule, double-counting risk) |
| **Issue** | M-P01 specified "one budget value per OCID". Phase 3 assumed every release of an OCID describes the same budget. Measurement shows **192 OCIDs carry two or more unrelated budget lines**. Each line has a different `planning.budget.projectID`, description and amount. For example, one NCC OCID holds a ₦20m consultancy study and a ₦987m Digital Nigeria Centre. Taking one budget per OCID silently drops ₦10.4bn of distinct planned budget. |
| **Evidence** | 97,749 distinct budget projectIDs. None spans more than one OCID. 189 of the 192 OCIDs are planning-only. Rule comparison (validation report §4): one-per-OCID total ₦93,817.4bn vs. per-budget-line total ₦93,827.8bn (DQ-06 EXTREME excluded). The budget differs in 191 OCIDs. |
| **Previous wording (M-P01 aggregation rule)** | `One budget value per OCID (process-snapshot rule); then SUM across OCIDs per buyer` |
| **Corrected wording** | One budget value per budget line `(OCID, projectID)`, taken from the latest release (integer release order) carrying that line. Then SUM across lines per buyer. OCIDs with more than one line are flagged `multi_project_flag = MULTI_PROJECT`. |
| **Reason** | The rule exists to stop the *same* budget being counted more than once. The budget-line grain still achieves that: a revised budget line is counted once, at its latest value. It also stops genuinely separate budget lines being discarded. |
| **Did the underlying Phase 3 decision change?** | The *intent* of the decision is unchanged: no double counting, and the process-snapshot rule still applies. The aggregation *grain* of M-P01 changes from OCID to budget line. This is a metric-definition change, so it needed project-owner approval, which was given on 2026-10-07. |
| **Other metrics affected** | None. OCID remains the process key for every other metric. The 3 non-planning-only multi-project OCIDs are handled at OCID level by the tender and award metrics, as before. |
| **Impact on schema design** | `stg.planning` gains `budget_id` and `budget_project_id`. `analytics.vw_budget_lines` provides the budget-line grain. See `docs/phase4_relational_model.md` v1.1 §6.2. |
| **Status** | Applied ✓ |

---

## Not Changed in This Pass

`phase3_metric_eligibility.md` §1.3 says "deduplicate at award ID level within
an OCID". The validation found this rule has no effect: award IDs never repeat
across releases. The section-level snapshot rule supersedes it. That
supersession is recorded in `docs/phase4_relational_model.md` §17 (issue 17.3)
rather than as a Phase 3 text correction, because it does not change any
metric's result.

---

## Phase 3 Freeze Status

> Phase 3 documentation is re-frozen as of 2026-10-07 at
> `phase3_metric_eligibility.md` v1.2.

---

*Correction log version: 1.0 — 2026-10-07*
