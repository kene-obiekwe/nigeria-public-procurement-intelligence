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
rule against the raw data. C-11 was added on 2026-10-08 after the Phase 8 review. C-12 was added on 2026-10-17 in Phase 10.1, after the Phase 10 source checks.

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

## Correction C-11 — New Issue DQ-20 (Portal Test Entity)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-11 |
| **Document** | `docs/phase3_data_quality/phase3_data_quality_decision_log.md`: new issue DQ-20, summary-matrix row, flag specification row |
| **Issue** | The Phase 8 review found that `TEST MINISTRY - NOCOPO` (`NG-BPP-BPP-NOC-90`; 427 releases, 412 OCIDs, 183 active valid awards worth NGN 72.0bn) was included in every analytical metric and in the entity rankings. It is a portal test artefact. |
| **Change** | DQ-20 added: RETAIN in `stg`/`core` + FLAG (`core.dim_buyer.test_entity_flag = TEST_ENTITY`) + EXCLUDE_FROM_METRIC for all analytical metrics, including M-E03 lifecycle counts, the entity benchmark and the `vw_dq_impact` populations. No staging row is deleted. A scan for other test or dummy entities (whole-word match on test, demo, dummy, sample, trial, nocopo in buyer and supplier IDs and names) found none. |
| **Did an existing Phase 3 decision change?** | Yes, in effect: the metric populations in `phase3_metric_eligibility.md` v1.2 now also exclude this buyer. The metric definitions are unchanged; only the eligible and candidate populations shrink (see the before/after table in `docs/phase8_analysis/phase8_1_dq20_and_performance.md`). |
| **Implemented in** | `core.dim_buyer.test_entity_flag` (DDL v1.4; migration `sql/02_schema/01_migration_v1_4.sql`); `test_entity_flag IS NULL` in every `sql/05_views` view; checks EN-15 to EN-19 (Gate B), AV-19 to AV-21 (Phase 7), DQI-16 to DQI-19 (Phase 8) |
| **Approved by** | Project owner, 2026-10-08 |
| **Status** | Applied ✓ |

---

## Correction C-12 — Release-Date Range (DQ-10 Observed Problem)

| Attribute | Detail |
|-----------|--------|
| **Correction ID** | C-12 |
| **Documents** | `phase3_data_quality_decision_log.md` DQ-10 (observed problem, evidence) and summary-matrix label; `phase3_data_dictionary.md` §1.3 `release_date`; `docs/phase2_profiling/data_profiling_report.md` §13 row 10 and §14 question 1 (dated correction note, original kept); `docs/phase2_profiling/targeted_validation_report.md` §5 (dated correction note, original kept); `docs/phase4_data_model/phase4_relational_model.md` §6.2 and §10; `data/README.md`; `README.md` audit table. Comment and message text only in `sql/02_schema/00_draft_core_schema.sql`, `sql/04_transformations/03_process_snapshot.sql`, `python/ingest/01_load_staging.py`, and the hard-coded report sentences in `python/profiling/01_structural_profiler.py` and `02_targeted_validation.py`. |
| **Issue** | These documents said every one of the 108,277 releases carries `date = 2021-05-03T22:44:00Z`. That value is the package `publishedDate`. The Phase 2 statement came from a sample (profiler) and from a sentence written into the script as text (targeted validation); it was never measured across the file. Found during the Phase 10 source checks. |
| **Evidence** | `docs/phase10_findings/source_verification.md` §D (`python/validation/08_verify_source_items.py`, raw file, SHA-256 checked): release dates run from `2021-05-03T22:44:00Z` to `2026-07-29T11:17:00Z`; 9,786 distinct values; 786 releases carry the package date. In all 6,280 multi-release OCIDs, no release with a lower integer ID has a later date. `stg.releases.release_date` gives the same range. |
| **Previous wording (DQ-10)** | `All 108,277 releases carry date = 2021-05-03T22:44:00Z - the OCDS package publication date, not the individual procurement event date.` |
| **Corrected wording** | The release-level `date` is publication metadata, not the procurement event date. Releases are dated 2021-05-03 to 2026-07-29 (9,786 distinct values); the package `publishedDate` is 2021-05-03. |
| **Did the underlying Phase 3 decision change?** | No. The DQ-10 rule stands: the release date is publication metadata and is never used as a procurement event date. The snapshot rule never used it (it orders releases by integer `release_seq`), and integer order agrees with date order in every multi-release OCID. |
| **Impact on metrics** | None. No figure changes. The DQ-09 FUTURE class (event dates in 2026 to 2050) was re-checked against the new range: none of the 24 dates it flags in the four event-date columns used by the timing metrics (award date 9, contract signature 4, tender start 5, tender end 6) falls on or before the last release date, 2026-07-29, so the class excludes no event that could already have happened. |
| **Approved by** | Project owner, 2026-10-17 (Phase 10 proposal) |
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
> Re-frozen on 2026-10-08 after C-11: `phase3_data_quality_decision_log.md` v1.4 (DQ-20).
> Re-frozen on 2026-10-17 after C-12: `phase3_data_quality_decision_log.md` v1.5, `phase3_data_dictionary.md` v1.3.

---

*Correction log version: 1.4 — 2026-10-17 (C-12 added in Phase 10.1)*
*Version 1.3 — 2026-10-08 (C-11 added in Phase 8.1)*
*Version 1.2 — 2026-10-07 (C-07 to C-09 added in Phase 6; C-10 in Phase 7)*
