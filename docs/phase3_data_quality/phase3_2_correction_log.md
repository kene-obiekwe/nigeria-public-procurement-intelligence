# Phase 3.2 Correction Log
# Nigeria Public Procurement Intelligence

> **Phase:** 3.2 — Specification Correction Pass
> **Correction date:** 2026-10-07
> **Approved by:** Project owner (2026-10-07)
> **Reviewed against:** `docs/phase3_data_quality/phase3_metric_eligibility.md` v1.1 (2026-08-18)
> **Evidence:** `docs/phase4_data_model/phase4_1_snapshot_validation_report.md`
> **Raw dataset:** NOT modified.

---

## Purpose

Phase 3 documentation was frozen on 2026-08-18. Changes are allowed only
through an explicitly approved correction pass. This log records the corrections
made in the Phase 3.2 pass (C-06 to C-10). It arose from the Phase 4.1 validation of the process-snapshot
rule against the raw data.

---

## Correction C-06 — M-P01 Budget Aggregation Grain

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-06 |
| **Document** | `docs/phase3_data_quality/phase3_metric_eligibility.md`: §1.3 (double-counting table), Pillar 1 (valid population, double-counting risks), M-P01 (aggregation rule, double-counting risk) |
| **Issue** | M-P01 specified "one budget value per OCID". Phase 3 assumed every release of an OCID describes the same budget. Measurement shows **192 OCIDs carry two or more unrelated budget lines**. Each line has a different `planning.budget.projectID`, description and amount. For example, one NCC OCID holds a ₦20m consultancy study and a ₦987m Digital Nigeria Centre. Taking one budget per OCID silently drops ₦10.4bn of distinct planned budget. |
| **Evidence** | 97,749 distinct budget projectIDs. None spans more than one OCID. 189 of the 192 OCIDs are planning-only. Rule comparison (validation report §4): one-per-OCID total ₦93,817.4bn vs. per-budget-line total ₦93,827.8bn (DQ-06 EXTREME excluded). The budget differs in 191 OCIDs. |
| **Previous wording (M-P01 aggregation rule)** | `One budget value per OCID (process-snapshot rule); then SUM across OCIDs per buyer` |
| **Corrected wording** | One budget value per budget line `(OCID, projectID)`, taken from the latest release (integer release order) carrying that line. Then SUM across lines per buyer. OCIDs with more than one line are flagged `multi_project_flag = MULTI_PROJECT`. |
| **Reason** | The rule exists to stop the *same* budget being counted more than once. The budget-line grain still achieves that: a revised budget line is counted once, at its latest value. It also stops genuinely separate budget lines being discarded. |
| **Did the underlying Phase 3 decision change?** | The *intent* of the decision is unchanged: no double counting, and the process-snapshot rule still applies. The aggregation *grain* of M-P01 changes from OCID to budget line. This is a metric-definition change, so it needed project-owner approval, which was given on 2026-10-07. |
| **Other metrics affected** | None. OCID remains the process key for every other metric. The 3 non-planning-only multi-project OCIDs are handled at OCID level by the tender and award metrics, as before. |
| **Impact on schema design** | `stg.planning` gains `budget_id` and `budget_project_id`. `analytics.vw_budget_lines` provides the budget-line grain. See `docs/phase4_data_model/phase4_relational_model.md` v1.1 §6.2. |
| **Status** | Applied ✓ |

---

## Correction C-07 — DQ-04 ELEVATED Tenderer Count

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-07 |
| **Document** | `docs/phase3_data_quality/phase3_data_quality_decision_log.md` — DQ-04 (Observed problem) |
| **Issue** | DQ-04 stated "79 records report 101-1,000 tenderers". The `ELEVATED` band (101–1,000) actually contains **14** records. 79 is the count of *all* records above 100 tenderers (14 ELEVATED + 65 ANOMALOUS). |
| **Evidence** | Phase 5: SQL-generated `tenderer_count_flag` and an independent Python re-count both give ELEVATED = 14 and ANOMALOUS = 65 (`docs/phase5_staging/phase5_staging_results.md`). Phase 6 check MD-10 (`sql/03_data_quality/05_monetary_and_date_validity.sql`). |
| **Previous wording** | `79 records report 101-1,000 tenderers.` |
| **Corrected wording** | `14 records report 101-1,000 tenderers.` (with a note on the previous figure) |
| **Did the underlying Phase 3 decision change?** | No. The DQ-04 treatment (RETAIN + FLAG `ELEVATED`) and the thresholds are unchanged. Only the reported count was wrong. |
| **Impact on metrics** | None. M-C01/M-C02 exclude ANOMALOUS (65) and keep ELEVATED (14), as specified. The sensitivity population (1–1,000) is 14 records larger than the primary population (1–100), not 79. |
| **Approved by** | Project owner, 2026-10-07 |
| **Status** | Applied ✓ |

---

## Correction C-08 — Tender / Contract Value Semantics (Observation O-1)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-08 |
| **Document** | `docs/phase3_data_quality/phase3_data_dictionary.md` — §4.1 `tender_value_amount` (quality issues, analytical role, notes); §5.2 `award_value_amount` (notes) |
| **Issue** | The dictionary said tender value "often" equals award value and listed it as an input to Pillar 4. Measurement shows it equals award value in **every** case. |
| **Evidence** | Tender value = award value in 17,417 / 17,417 tender–award pairs. Contract value = award value in 17,043 / 17,043 contracts. Tender value = 0 in 991 / 991 tenders without an award. Phase 6 checks OB-01 to OB-03 (`sql/03_data_quality/08_observations.sql`). |
| **Corrected wording** | Tender value is not an independent estimate and must not be used for tender-vs-award variance. Award value is the single published value per process. Pillar 4 / business question 3 compare **budget vs. award only**. |
| **Did the underlying Phase 3 decision change?** | No metric changes. M-P01 (budget) and M-V01 (award) are unaffected. This narrows the *permissible comparisons* in Pillar 4, as the Data-Quality Plan §10 requires ("do not compare … until their meaning is sufficiently compatible"). |
| **Approved by** | Project owner, 2026-10-07 (O-1 acknowledged) |
| **Status** | Applied ✓ |

---

## Correction C-09 — Field-Name Artefact Repair (completes C-05)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-09 |
| **Document** | `docs/phase3_data_quality/phase3_data_quality_decision_log.md` — 9 "Data field / entity" table cells |
| **Issue** | C-05 (Phase 3.1) reported 0 remaining escape artefacts. 9 instances of `\releases[]` had been rendered as a line break followed by `eleases[]`. This split those table rows and showed the field name without its leading "r". |
| **Corrected wording** | `releases[]...` restored on the same table row (e.g. `| **Data field / entity** | releases[].ocid |`). |
| **Did the underlying Phase 3 decision change?** | No. This is a rendering repair only. |
| **Status** | Applied ✓ (0 remaining `eleases[` line starts in Phase 3 documents) |

---

## Correction C-10 — New Issue DQ-19 (Incomplete Buyer Identifier)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-10 |
| **Document** | `docs/phase3_data_quality/phase3_data_quality_decision_log.md`: new issue DQ-19, summary-matrix row, flag specification row |
| **Issue** | Phase 3 had no buyer-side counterpart to DQ-14. Phase 6 found 26 releases whose buyer ID is the bare prefix `NG-BPP-` (Gate B check EN-03). |
| **Change** | DQ-19 added: RETAIN + FLAG (`buyer_id_flag = INCOMPLETE`) + EXCLUDE_FROM_METRIC for entity-level comparisons; retained in overall process counts. |
| **Did an existing Phase 3 decision change?** | No. This is a new issue, handled the same way as the approved DQ-14 treatment. |
| **Implemented in** | `core.dim_buyer.buyer_id_flag` (DDL v1.3); `analytics.vw_budget_eligible` and `analytics.vw_entity_benchmark` exclude it (Phase 7 checks SP-05, AV-15) |
| **Approved by** | Project owner, 2026-10-07 |
| **Status** | Applied ✓ |

---

## Not Changed in This Pass

`phase3_metric_eligibility.md` §1.3 says "deduplicate at award ID level within
an OCID". The validation found this rule has no effect: award IDs never repeat
across releases. The section-level snapshot rule supersedes it. That
supersession is recorded in `docs/phase4_data_model/phase4_relational_model.md` §17 (issue 17.3)
rather than as a Phase 3 text correction, because it does not change any
metric's result.

---

## Phase 3 Freeze Status

> Phase 3 documentation is re-frozen as of 2026-10-07 at:
> `phase3_metric_eligibility.md` v1.2 (C-06), `phase3_data_quality_decision_log.md` v1.3
> (C-07, C-09, C-10), `phase3_data_dictionary.md` v1.2 (C-08).

---

*Correction log version: 1.2 — 2026-10-07 (C-07 to C-09 added in Phase 6; C-10 in Phase 7)*
