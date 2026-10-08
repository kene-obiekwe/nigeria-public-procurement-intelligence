# Phase 8: Business-Question SQL Analysis
# Nigeria Public Procurement Intelligence

> **Phase:** 8 — Business-Question SQL Analysis
> **Date:** 2026-10-08
> **Status:** Seven scripts built, run and spot-checked. **27 / 27 validation GATE checks passed** (2 INFO).
> Phase 7 and Gate B are unchanged: no `stg.*` or `core.*` object was modified.
> **Results log:** `docs/phase8_analysis/phase8_analysis_results.md`
> (`python/validation/05_run_analysis_scripts.py`)
> **Validation log:** `docs/phase8_analysis/phase8_validation_results.md`
> (`python/validation/04_run_validation_suite.py --phase 8`)

---

## 1. Exit Gate

The Implementation Plan's Phase 8 gate: "every core business question has a
reproducible SQL script whose output has been spot-checked and whose
limitations are noted alongside the result."

- **Reproducible.** One script per question in `sql/06_analysis/`. Each result
  set is labelled `-- [RSn]`. The runner executes them all in a read-only
  transaction and writes the results log.
- **Limited to `analytics.*`.** The runner fails a script that mentions `stg.` or
  `core.` outside comments, or that contains DDL or DML. All seven pass.
- **Spot-checked.** Fourteen headline figures (BQ-01 to BQ-14) are recomputed
  from `stg.*` with a formulation independent of the analytics views, and match
  exactly. Two further hand checks: the top supplier's two awards in `stg`
  sum to ₦210.29bn (RS3 of script 01), and the method-level single-bidder rates
  for Direct Procurement (89.4% of 1,101) and National Competitive Bidding
  (39.6% of 10,296) match a direct count on the latest tender release.
- **Limitations stay with the result.** Each script's header lists the
  limitations to state with every figure; population sizes and minimum-n
  warnings appear in the result sets themselves.

---

## 2. Script Catalogue

| Script | Business question | Metric(s) | Main view(s) | Result sets |
|---|---|---|---|---|
| `01_supplier_concentration.sql` | 1. Supplier concentration | M-S01 | `vw_supplier_award_eligible` | population and exclusion; top-N shares, Herfindahl index; top 20 suppliers; by procurement method; by entity |
| `02_competition.sql` | 2. Competition | M-C01, M-C02 | `vw_competition_eligible` | primary and sensitivity populations; participation bands; percentiles; by method; by tender status; entities at both extremes |
| `03_budget_to_award.sql` | 3. Budget-to-award variance | Pillar 4 | `vw_budget_award_comparison` | population and totals; ratio percentiles; ratio bands; by method; by entity (net variance, median ratio); double-count check |
| `04_procurement_cycle_timing.sql` | 4. Cycle timing and date completeness | M-E01, M-E02, signature lag | `vw_tender_duration_eligible`, `vw_award_lag_eligible`, `vw_signature_lag_eligible` | medians; distributions; duration bands; by method; by year with year-on-year change |
| `05_entity_benchmarking.sql` | 5. Entity benchmarking | all entity KPIs | `vw_entity_benchmark` | population; activity concentration; top 15 entities; KPI profile with percentile positions; KPI spread; KPI by value quartile |
| `06_implementation_coverage.sql` | 6. Implementation coverage | M-I01, M-E03 | `vw_contract_implementation_coverage`, `vw_lifecycle_stage` | headline rate; data type; by status; entity distribution and lowest coverage; lifecycle funnel |
| `07_data_quality_impact.sql` | 7. Data-quality impact | all | `vw_dq_impact` | exclusions by metric; issue-by-metric matrix with materiality; issue ranking |

Techniques used where the question needs them: window functions for rank,
cumulative share and percentile position (`rank`, `row_number`, `ntile`,
`percent_rank`, `sum() OVER`, `lag`); CTEs to isolate comparable records and
to hold the minimum-n parameters; `CASE` classification for bands and
materiality; `FILTER` and `percentile_cont` for medians and rates.

Each script's first result set gives the eligible population next to its
candidate population. The second (`RS1b`) reads the register entry from
`analytics.vw_metric_population`. The register takes about 40 s because it
evaluates every view, so a full run takes several minutes; `--skip-register`
skips those result sets during development.

---

## 3. New View: `analytics.vw_dq_impact`

**Why it exists.** Business question 7 asks which data-quality issue caused
each exclusion. The eligible-only `analytics.*` views cannot show this. Kene
chose option 1 on 2026-10-08: add one view, rather than let the script read
`stg`/`core`. This is the single exception to the prompt's "no new views" rule
and is recorded here.

**Where.** `sql/05_views/09_dq_impact.sql` (re-runnable, `CREATE OR REPLACE`).

**Design.**
- One row per (metric, issue), plus a `SUMMARY_ALL` row per metric and a
  `SUMMARY_OTHER` row for non-DQ rules (status, missing values or dates).
- `records_with_issue` counts candidates that trip the issue; it overlaps
  across issues. `records_lost_only_to_issue` counts those removed by that
  issue alone and is additive. For each metric, single-cause losses plus
  records lost to several reasons equal `candidate − eligible`.
- Eligible counts and values come from the analytics views, so the attribution
  is tested against the eligibility rules, not assumed to match them.
- `DISCLOSED` rows (DQ-01, DQ-02, DQ-11, DQ-12, DQ-13) keep the records and
  describe how the issue limits interpretation.
- It reads `core.*` and `stg.*` because it has to see the excluded side. It is
  the only analytics view designed to do so. The BQ7 script reads only the view.
- Issues DQ-03, DQ-10, DQ-15 and DQ-17 have no record-level footprint in a
  metric population and are not counted.

**Validation.** `sql/03_data_quality/10_business_question_checks.sql`, checks
DQI-01 to DQI-13: reconciliation to every metric's candidate and eligible
counts, to `vw_metric_population`, and to independently counted footprints
(DQ-04, DQ-05, DQ-06, DQ-07, DQ-14 count and value, and the two date-order
conflicts, 141 and 756). All pass.

**Performance.** About 50 s per evaluation: it evaluates nine analytics views
and the process snapshot repeatedly. Script 07 therefore takes about 2 minutes.
See §6.

---

## 4. Findings by Question

All figures are for the pinned source file (SHA-256 `6151466…bc90c`) and its
process snapshot. They are descriptive patterns, not conclusions about
conduct. Each states the eligible population it rests on.

### 4.1 Supplier concentration (M-S01)

- **Population.** 13,694 of 15,946 eligible awards (85.9%) have a usable
  supplier ID: 9,941 suppliers, ₦2,686.8bn.
- **Disclosure.** 2,252 awards (₦675.8bn, **20.1% of eligible award value**)
  carry only the bare `NG-BPP-` supplier ID and are excluded. Concentration is
  measured on the remaining awards. Supplier IDs are not merged (DQ-13: 1,483
  IDs with several names; DQ-14), so the figures are a lower bound.
- **Overall.** The largest supplier holds 7.8% of value, the top 5 hold 20.9%,
  the top 10 hold 28.5%, the top 100 hold 59.4%. The Herfindahl index is
  about 135 on a 0–10,000 scale. 45 suppliers account for half the value; 880
  for 80%. 7,763 suppliers (78%) have one award. The top share rests on one
  award of ₦210bn, so it is sensitive to single large records.
- **By method.** Concentration is low in National Competitive Bidding (top
  supplier 6.6%) and high in Emergency (61.4%, 364 awards) and in awards with no
  stated method (57.5%, 106 awards).
- **By entity** (167 entities with at least 10 eligible awards). The median
  entity's largest supplier holds 21.2% of its award value. In 14 entities one
  supplier holds half or more.

### 4.2 Competition (M-C01, M-C02)

- **Population.** 17,469 primary tenders (1–100 tenderers); 17,482 in the
  sensitivity population.
- **Overall.** Median 2 tenderers. 44.0% of primary tenders (7,681) have a
  single bidder; 88.8% have five or fewer. The 90th percentile is 6, the 99th
  is 20, the maximum is 90. Adding the 13 elevated tenders changes the
  single-bidder rate by 0.03 points.
- **By method.** Single-bidder rates are 89.4% for Direct Procurement, 87.5%
  for Sole Source and 87.2% for Repeat Procurement, which are close to
  single-supplier by design. For National Competitive Bidding the rate is
  39.6%, and for National Shopping 23.6%. Method must be held constant when
  comparing entities.
- **By status.** Rates are similar across complete (42.7%), active (46.0%) and
  planned (42.9%) tenders (Kene I-3: segmentation only).
- **By entity** (104 entities with at least 30 primary tenders). Single-bidder
  rates run from 0% (six entities) to 100% (two entities).

### 4.3 Budget-to-award (Pillar 4)

- **Population.** 15,753 OCIDs (98.8% of 15,946 eligible awards). Excluded: 131
  with no budget line, 3 multi-project (Kene I-2) and 59 with a zero or extreme
  budget.
- **Overall.** Budgets total ₦12,583.7bn and awards ₦3,163.1bn (aggregate
  ratio 0.25); the typical OCID is close (median 0.93). 42.4% of OCIDs are
  within 10% of budget; 33.9% are below half of budget; 229 (1.5%) exceed ten
  times budget and hold 48.7% of award value.
- **Concentration of the difference.** Across the 172 entities with at least
  10 comparable OCIDs, the largest net difference (Federal Ministry of Works &
  Housing, headquarters) accounts for 56% of the summed absolute difference.
- **Reading.** A budget is a plan; an award below budget is not a saving, and
  one above it is not an overrun. No budget line is reused across OCIDs
  (RS7), so totals are not inflated by sharing. Ratios span 0 to about 1.7
  billion; extremes are retained and shown in their own band, and need
  checking against the source.

### 4.4 Procurement-cycle timing (M-E01, M-E02, signature lag)

| Measure | Eligible n | Coverage of candidate | Median | 90th percentile | Over 1 year |
|---|---|---|---|---|---|
| Tender open duration | 9,180 | 52.1% | 28 days | 64 days | 0.7% |
| Award lag (tender start → award) | 7,569 | 45.3% | 94 days | 266 days | 3.9% |
| Signature lag (award → signed) | 12,138 | 74.0% | 5 days | 62 days | 1.3% |

- **Date completeness limits every result.** Fewer than half the tenders can
  support an award lag. The results describe the processes that published valid
  dates; they say nothing about the rest.
- **By method.** Award lag is 9 days for Emergency, 43 for Selective
  Tendering, 112 for Direct Procurement and 115 for National Competitive
  Bidding.
- **By year.** Medians vary by year (tender duration 18 days in 2020, 42 in 2021).
  The analysis reports the pattern without attributing a cause.
- 3,853 signature lags are same-day (31.7%).

### 4.5 Procuring-entity benchmarking

- **Activity is concentrated.** Of 666 entities, the largest holds 39.7% of
  eligible award value, the top 10 hold 75.3% (but 26.8% of processes) and the
  top 100 hold 97.6%. The top quartile by value (65 entities) holds 94.8%.
- **Spread of KPIs** (entities above each minimum n): median single-bidder rate
  41.5% (104 entities), median top-supplier share 22.2% (174), median
  implementation coverage 99.0% (124), median tender reach 6.5% (374).
- **Ranks differ by measure.** An entity can be high on value yet low on
  process count (Federal Medical Centre, Taraba: 10 awards worth ₦175.8bn). RS3
  and RS4 show each entity's rank and percentile on every KPI beside its own n.

### 4.6 Implementation reporting coverage (M-I01, M-E03)

- **Coverage.** 14,304 of 16,392 contracts (87.3%) carry implementation data;
  79.1% have transactions and milestones, 8.2% milestones only, 12.7% none.
  Status matters little (active 87.0%) except pending (74.6%).
- **By entity** (124 entities with at least 20 contracts). 52 have full
  coverage; 48 more have 90% to under 100%; 6 have under half, one of them
  with none. The
  Federal Ministry of Works & Housing (headquarters, 1,677 contracts) is at 21.6%.
  This is reporting coverage, not contract performance.
- **Lifecycle.** 82.2% of 98,866 OCIDs were published at planning stage only
  (DQ-02). Of OCIDs reaching the tender stage, 94.9% reach award; of those,
  98.1% reach contract; of those, 87.3% reach implementation.

### 4.7 Data-quality impact

- **Largest effects on the metrics:**
  - M-S01: DQ-14 (20.1% of candidate value excluded) and DQ-13 (33% of the
    eligible value sits with supplier IDs that have several name variants).
  - M-P01: DQ-06 extreme budgets are 32 lines but 50.7% of candidate budget
    value (₦96.4 trillion), so they would dominate any total.
  - M-V01: the single DQ-07 award is 22.9% of candidate award value.
  - M-E03, M-I01: DQ-02 (82% of OCIDs planning only); DQ-11 and DQ-12
    (79% of contracts have transactions without dates or reliable values).
- **Timing metrics lose the most records** (M-E01 47.9%, M-E02 54.7%, signature
  lag 26.0%), almost entirely to missing dates, not to numbered DQ issues
  (8,413 of M-E01's 8,443 exclusions). Chronology conflicts remove 141 award-lag
  and 756 signature-lag records.
- **Small footprints.** DQ-04, DQ-05, DQ-08, DQ-09, DQ-16, DQ-18, DQ-19 and the
  multi-project rule each touch under 2% of records in the metrics they affect.
- **Materiality** uses an analyst's reading rule (high 10%, moderate 1%; see
  the script header). It is not a project rule and does not claim the data are
  wrong.

---

## 5. Decisions and Observations for Kene

| # | Item | Recommendation |
|---|---|---|
| D-1 | **Test entity.** An entity named `TEST MINISTRY - NOCOPO` (`NG-BPP-BPP-NOC-90`) is in the data: 412 processes, 183 awards worth ₦72bn, ₦530bn of budget lines. No approved DQ rule covers it, so it is retained and appears in rankings (entity benchmark, concentration and budget-variance lists). | Decide whether to log it as a new data-quality issue (for example DQ-20) with treatment FLAG or EXCLUDE_FROM_METRIC for entity-level results. A named test entity is a plausible technical artefact, but it should not be removed without a logged decision. |
| D-2 | **`vw_dq_impact` status.** It reads `core`/`stg` by design and is validated by DQI-01 to DQI-13. | Confirm it counts as a validated view for Gate C (Power BI). |
| D-3 | **Parameters.** Minimum n per comparison (10 awards, 30 tenders, 20 contracts, 30 for method/year groups) and the 10% / 1% materiality thresholds are analyst choices stated in each script. | Confirm or change before the figures are used in Phase 9. |
| D-4 | **Performance.** Views are 1–4 s each; the register takes about 40 s and `vw_dq_impact` about 50 s, because the process snapshot is re-evaluated in every view. | Decide at the start of Phase 9 whether to add `stg.releases (ocid, release_seq)` and materialise the snapshot, based on the Power BI refresh pattern (Phase 7 §5). |
| O-1 | Values to verify against the source before use: the ₦210bn award behind the top supplier; Federal Medical Centre, Taraba (₦175.8bn from 10 awards); HADEJIA-JAMAĻARE RBDA, as spelled in the source (award ₦86.2bn against ₦4.0bn budget, ratio 21×). | Treated as observed anomalies requiring further validation. Nothing is excluded. |

---

## 6. Reproduce

```bash
.venv/Scripts/python python/validation/05_run_analysis_scripts.py
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 8
```

To create the new view on a fresh database:

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/09_dq_impact.sql
```

A single script can be run with `psql -f sql/06_analysis/0N_*.sql` or with
`--only 0N`.

---

*Phase 8 log version 1.0 — 2026-10-08. Raw dataset not modified; stg.* and core.* unchanged.*
