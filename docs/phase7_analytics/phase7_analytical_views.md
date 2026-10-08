# Phase 7: Analytical Layer & Reusable Views
# Nigeria Public Procurement Intelligence

> **Phase:** 7 — Analytical Layer & Reusable Views
> **Date:** 2026-10-07
> **Status:** Views built. **Phase 7 exit gate passed: 27 / 27 GATE checks**, 13 INFO measurements
> (re-run after Phase 8.1; it was 24 / 24 before the DQ-20 checks AV-19 to AV-21 were added).
> Gate B re-confirmed: 107 / 107 (102 plus EN-15 to EN-19).
> **Phase 8.1 (2026-10-08):** the portal test entity (DQ-20) is excluded from every view, and the
> process snapshot is materialised. Populations below are the **current** ones; the Phase 7
> original figures are kept in the "before" column of the table in
> `docs/phase8_analysis/phase8_1_dq20_and_performance.md`.
> **Results log:** `docs/phase7_analytics/phase7_view_validation_results.md`
> (`python/validation/04_run_validation_suite.py --phase 7`)
> **Eligibility source:** `docs/phase3_data_quality/phase3_metric_eligibility.md` v1.2,
> decision log v1.3 (DQ-19)

---

## 1. Exit Gate

The Implementation Plan's Phase 7 gate: "each view's row population matches its
documented eligibility definition, verified against a manual spot-check".

- **Population match (AV-01 to AV-18).** Each view's row count is recomputed
  directly from `stg.*` with an independent formulation (ROW_NUMBER latest
  release, rather than the DISTINCT ON core snapshot), and matches exactly.
  Entity totals reconcile to the metric views they are built from.
- **Spot checks (SP-01 to SP-06).** Named records behave as specified: the
  ₦1.004T FCTA award is excluded; the ×100-corrected JNCI award uses its
  latest value; the placeholder supplier `'1'` is replaced by the named
  supplier; there are no placeholder dates in timing views; the bare buyer is
  absent from the per-entity views; and repeated supplier entries are counted
  once.
- No stg.* row was modified. (Phase 8.1 added the `core.dim_buyer.test_entity_flag` column,
  indexes, and materialised the two snapshot views; no row of `stg.*` changed.)

---

## 2. View Catalogue and Eligible Populations

All views are in schema `analytics`, defined in `sql/05_views/`, and
re-runnable (`CREATE OR REPLACE`). Populations are as of 2026-10-07 and are
live in `analytics.vw_metric_population`.

| View | Metric(s) | Grain | Candidate population | Candidate | Eligible | % |
|---|---|---|---|---|---|---|
| `vw_budget_eligible` | M-P01 | budget line | Budget lines (C-06) | 97,353 | 96,802 | 99.4 |
| `vw_competition_eligible` (primary) | M-C01, M-C02 | OCID | Snapshot tenders | 17,405 | 17,253 | 99.1 |
| `vw_competition_eligible` (all rows) | M-C01 sensitivity | OCID | Snapshot tenders | 17,405 | 17,266 | 99.2 |
| `vw_award_value_eligible` | M-V01 | OCID (1 award) | Snapshot awards | 16,527 | 15,763 | 95.4 |
| `vw_supplier_award_eligible` | M-S01 | award × supplier | M-V01 eligible awards | 15,763 | 13,537 | 85.9 |
| `vw_budget_award_comparison` | Pillar 4 / BQ3 | OCID | M-V01 eligible awards | 15,763 | 15,574 | 98.8 |
| `vw_tender_duration_eligible` | M-E01 | OCID | Snapshot tenders | 17,405 | 9,040 | 51.9 |
| `vw_award_lag_eligible` | M-E02 | OCID | Snapshot OCIDs with tender + award | 16,527 | 7,462 | 45.2 |
| `vw_signature_lag_eligible` | Pillar 5 signature lag | contract | Snapshot contracts | 16,221 | 12,006 | 74.0 |
| `vw_lifecycle_stage` | M-E03 | OCID | All OCIDs (DQ-20 excluded) | 98,454 | 98,454 | 100.0 |
| `vw_contract_implementation_coverage` | M-I01 | contract | Snapshot contracts | 16,221 | 16,221 | 100.0 |
| `vw_entity_benchmark` | Entity benchmarking | buyer | Buyer IDs (DQ-20 excluded) | 666 | 665 | 99.8 |
| `vw_metric_population` | — | metric | Register of the rows above | — | — | — |

### Eligibility rules as implemented

Every rule below also requires that the buyer is not the DQ-20 portal test entity
(`core.dim_buyer.test_entity_flag IS NULL`). Candidate populations exclude it too.

| View | Conditions (all must hold) | Phase 3 source |
|---|---|---|
| `vw_budget_eligible` | latest release per budget line; amount ≥ 0; not EXTREME (DQ-06); not ZERO_VALUE (DQ-16); release not NO_PARTIES (DQ-18); buyer not INCOMPLETE (DQ-19) | Pillar 1, M-P01, C-06 |
| `vw_competition_eligible` | snapshot tender; status not null; tenderer flag NORMAL or ELEVATED. Primary = NORMAL (1–100) | Pillar 2, M-C01, M-C02 |
| `vw_award_value_eligible` | snapshot award; status `active`; not EXTREME (DQ-07); not ZERO_VALUE | Pillar 4, M-V01 |
| `vw_supplier_award_eligible` | M-V01 conditions; supplier ID not INCOMPLETE (DQ-14); repeated `suppliers[]` entries collapsed (O-3) | Pillar 3, M-S01 |
| `vw_budget_award_comparison` | M-V01 eligible award; exactly one budget line; budget > 0, not EXTREME, not ZERO | Pillar 4, C-08 |
| `vw_tender_duration_eligible` | both tender dates VALID; end ≥ start | Pillar 5, M-E01 |
| `vw_award_lag_eligible` | tender start and award date VALID; award ≥ tender start; single-award OCID | Pillar 5, M-E02, C-03 |
| `vw_signature_lag_eligible` | award date and date signed VALID; signed ≥ award | Pillar 5 (no metric ID) |
| `vw_lifecycle_stage` | none (highest stage across all releases) | M-E03 |
| `vw_contract_implementation_coverage` | none (one snapshot contract per OCID) | M-I01 |
| `vw_entity_benchmark` | buyer not INCOMPLETE (DQ-19); each measure inherits its metric view's rule | Implementation Plan Phase 7 |

---

## 3. Exclusion Waterfalls and Disclosures

| Ref | Measure | Value | Use |
|---|---|---|---|
| WF-01 | Snapshot awards not `active` (cancelled 367, pending 128, unsuccessful 25, null 2) | 522 | M-V01 excluded |
| WF-02 | Active awards that are EXTREME or ZERO_VALUE | 242 | M-V01 excluded |
| WF-03 / 04 / 05 | **M-S01: eligible awards whose only supplier ID is the bare `NG-BPP-`** | **2,226 awards; ₦670.4bn; 20.4% of M-V01 award value** | **Must be disclosed with every M-S01 figure** |
| WF-06a | Eligible awards with no planning budget line | 128 | Budget-to-award excluded |
| WF-06b | Eligible awards in MULTI_PROJECT OCIDs | 3 | Budget-to-award excluded |
| WF-06c | Single budget line but zero or EXTREME budget | 58 | Budget-to-award excluded |
| WF-07 | VALID dates but award before tender start (process level) | 135 | M-E02 excluded |
| WF-08 | VALID dates but contract signed before award (process level) | 734 | Signature lag excluded |
| WF-09 | M-C01 primary median tenderers | 2 | Matches the Phase 3 caveat |
| WF-10 | Tender releases with a VALID start / eligible M-E01 OCIDs | 9,593 / 9,040 | Confirms the Phase 3 note (C-04) |

**Date conflicts: release vs. process level.** Phase 6 measured 149 and 792
across *all* releases (checks MD-18 and MD-19). The analytical views work on
the process snapshot, so the conflicts that actually reach the metrics are
135 (award before tender) and 734 (signed before award); before the DQ-20 exclusion they were
141 and 756. All are excluded, as
Kene decided. Of the approved metrics, the award-before-tender conflict
affects only M-E02. The signed-before-award conflict affects only the Pillar 5
signature lag.

---

## 4. Interpretations Made While Encoding the Rules

Each item is a gap or ambiguity in the Phase 3 text, resolved conservatively
and visibly. Items marked **confirm** should be reviewed.

| # | Interpretation | Why | Status |
|---|---|---|---|
| I-1 | Budget-to-award uses the M-V01 award population (active, non-extreme, non-zero) | Pillar 4 states no status rule. A cancelled award is not "awarded value". This is consistent with M-V01. | **confirm** |
| I-2 | Budget-to-award requires exactly one budget line (excludes 3 MULTI_PROJECT OCIDs) | No rule says which unrelated budget line an award answers. This mirrors the C-03 single-award restriction. | **confirm** |
| I-3 | Competition includes tenders of any non-null status (e.g. `planned` 506, `cancelled` 32, `withdrawn` 19) | Pillar 2 requires only "status not null". Status is carried as a column for Phase 8 segmentation. | **confirm** |
| I-4 | M-E02 does not filter on award status | M-E02 specifies none. Status is carried as a column. | Note |
| I-5 | M-S01 attributes the full award value to its supplier | Every award has exactly one distinct supplier (EN-13, AV-07). Phase 3 defines no split rule; AV-07 fails if that ever changes. | Guarded |
| I-6 | The M-E02 single-award guard (C-03) is always true after the snapshot | At most 1 award per release and one award release per OCID. Kept so the rule stays explicit. | Note |
| I-7 | Signature lag is implemented although it has no metric ID | Pillar 5 defines its valid population explicitly, and Kene's date-conflict decision applies to it. | Note |

---

## 5. Performance Note

Phase 7 originally left every view reading the process snapshot as a plain view (a sort of
108,277 releases per use). Single views took 1–5 s, and `vw_metric_population` about 40 s.
Phase 8.1 added the index `stg.releases (ocid, release_seq DESC)` and materialised
`core.vw_budget_lines` and `core.vw_process_snapshot` (same names, with indexes). Every view
now returns in under 1 s and the register in about 3 s. Before/after timings:
`docs/phase8_analysis/phase8_1_dq20_and_performance.md`. After any change to `stg.*` or
`core.dim_buyer`, run `sql/04_transformations/04_refresh_snapshot.sql`.

---

## 6. Reproduce

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/04_transformations/03_process_snapshot.sql -f sql/05_views/01_budget_eligible.sql -f sql/05_views/02_competition_eligible.sql -f sql/05_views/03_award_and_supplier_eligible.sql -f sql/05_views/04_budget_award_comparison.sql -f sql/05_views/05_timing_eligible.sql -f sql/05_views/06_lifecycle_and_implementation.sql -f sql/05_views/07_entity_benchmark.sql -f sql/05_views/08_metric_population.sql -f sql/05_views/09_dq_impact.sql
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 7
```

---

*Phase 7 log version 1.1 — 2026-10-08 (DQ-20 populations and performance, Phase 8.1). Raw dataset not modified; no stg.* row changed.*
