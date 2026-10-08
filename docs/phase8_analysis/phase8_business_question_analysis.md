# Phase 8: Business-Question SQL Analysis
# Nigeria Public Procurement Intelligence

> **Phase:** 8 — Business-Question SQL Analysis
> **Date:** 2026-10-08 (figures revised after Phase 8.1)
> **Status:** Seven scripts built, run and spot-checked. **31 / 31 validation GATE checks passed** (2 INFO).
> **Phase 8.1** removed the DQ-20 portal test entity from every population and rebuilt the analytical
> layer for speed: `docs/phase8_analysis/phase8_1_dq20_and_performance.md`. All figures below are the
> post-DQ-20 ones; the first-run figures are in the "before" columns of that document.
> Phase 7 (27 / 27) and Gate B (107 / 107) pass. No `stg.*` row was modified.
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
  exactly. Two further hand checks were made on the first run, before DQ-20: the top supplier's two
  awards in `stg` sum to ₦210.29bn (RS3 of script 01), and the method-level
  single-bidder rates for Direct Procurement and National Competitive Bidding match a
  direct count on the latest tender release. Neither involves the test entity, so both still hold
  (the top supplier still sums to ₦210.29bn; National Competitive Bidding is 39.6%).
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
`analytics.vw_metric_population`. Since Phase 8.1 the register takes about 3 s (it took about
40 s), and a full run of all seven scripts takes under a minute (it took about 10 minutes).
`--skip-register` still skips those result sets.

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
- DQ-20 (Phase 8.1): the test entity is removed before each candidate population is defined,
  so it stays outside `candidate − eligible`. Its footprint is reported separately as one
  `PRE_EXCLUDED` row per metric (`dq_ref` DQ-20).
- It reads `core.*` and `stg.*` because it has to see the excluded side. It is
  the only analytics view designed to do so. The BQ7 script reads only the view.
- Issues DQ-03, DQ-10, DQ-15 and DQ-17 have no record-level footprint in a
  metric population and are not counted.

**Validation.** `sql/03_data_quality/10_business_question_checks.sql`, checks
DQI-01 to DQI-13: reconciliation to every metric's candidate and eligible
counts, to `vw_metric_population`, and to independently counted footprints
(DQ-04, DQ-05, DQ-06, DQ-07, DQ-14 count and value, the two date-order
conflicts, now 135 and 734, and the DQ-20 footprint). DQI-01 to DQI-13 and
DQI-16 to DQI-19 are GATE checks (DQI-14 and DQI-15 are INFO). All pass.

**Performance.** About 43 s per evaluation on the first run, because it evaluated nine
analytics views and re-built the process snapshot each time. After Phase 8.1 (materialised
snapshot, index, fresh statistics) it takes about 3 to 5 s, and script 07 takes about 15 s.

---

## 4. Findings by Question

All figures are for the pinned source file (SHA-256 `6151466…bc90c`), its
process snapshot, and the post-DQ-20 populations (the portal test entity
`NG-BPP-BPP-NOC-90` is excluded). They are descriptive patterns, not conclusions about
conduct. Each states the eligible population it rests on.

### 4.1 Supplier concentration (M-S01)

- **Population.** 13,537 of 15,763 eligible awards (85.9%) have a usable
  supplier ID: 9,800 suppliers, ₦2,620.2bn.
- **Disclosure.** 2,226 awards (₦670.4bn, **20.4% of eligible award value**)
  carry only the bare `NG-BPP-` supplier ID and are excluded. Concentration is
  measured on the remaining awards. Supplier IDs are not merged (DQ-13: 1,483
  IDs with several names; DQ-14), so the figures are a lower bound.
- **Overall.** The largest supplier holds 8.0% of value, the top 5 hold 21.5%,
  the top 10 hold 29.0%, the top 100 hold 59.5%. The Herfindahl index is
  about 139 on a 0–10,000 scale. 45 suppliers account for half the value; 872
  for 80%. 7,631 suppliers (78%) have one award. The top share rests on one
  award of ₦210bn, so it is sensitive to single large records.
- **By method.** Concentration is low in National Competitive Bidding (top
  supplier 6.9%) and high in Emergency (61.4%, 363 awards) and in awards with no
  stated method (57.5%, 105 awards).
- **By entity** (166 entities with at least 10 eligible awards). The median
  entity's largest supplier holds 21.0% of its award value. In 13 entities one
  supplier holds half or more.

### 4.2 Competition (M-C01, M-C02)

- **Population.** 17,253 primary tenders (1–100 tenderers); 17,266 in the
  sensitivity population.
- **Overall.** Median 2 tenderers. 44.0% of primary tenders (7,599) have a
  single bidder; 88.7% have five or fewer. The 90th percentile is 6, the 99th
  is 20, the maximum is 90. Adding the 13 elevated tenders changes the
  single-bidder rate by 0.03 points.
- **By method.** Single-bidder rates are 89.5% for Direct Procurement, 87.2%
  for Sole Source and 87.1% for Repeat Procurement, which are close to
  single-supplier by design. For National Competitive Bidding the rate is
  39.6%, and for National Shopping 23.7%. Method must be held constant when
  comparing entities.
- **By status.** Rates are similar across complete (42.7%), active (46.2%) and
  planned (43.4%) tenders (Kene I-3: segmentation only).
- **By entity** (103 entities with at least 30 primary tenders). Single-bidder
  rates run from 0% (six entities) to 100% (two entities).

### 4.3 Budget-to-award (Pillar 4)

- **Population.** 15,574 OCIDs (98.8% of 15,763 eligible awards). Excluded: 128
  with no budget line, 3 multi-project (Kene I-2) and 58 with a zero or extreme
  budget.
- **Overall.** Budgets total ₦12,434.5bn and awards ₦3,091.5bn (aggregate
  ratio 0.25); the typical OCID is close (median 0.93). 42.2% of OCIDs are
  within 10% of budget; 34.0% are below half of budget; 227 (1.5%) exceed ten
  times budget and hold 49.8% of award value.
- **Concentration of the difference.** Across the 171 entities with at least
  10 comparable OCIDs, the largest net difference (Federal Ministry of Works &
  Housing, headquarters) accounts for 56.5% of the summed absolute difference.
- **Reading.** A budget is a plan; an award below budget is not a saving, and
  one above it is not an overrun. No budget line is reused across OCIDs
  (RS7), so totals are not inflated by sharing.
- **The extreme ratios (known limitation, not excluded).** The ratio runs from 0 to about
  1.71 billion. All 4 OCIDs with a ratio of one million or more have recorded budgets under
  ₦100,000 (for example ₦1, ₦15, ₦52 and ₦55). In total 16 comparable OCIDs record a budget
  under ₦100,000; these look like placeholder-like entries rather than real budgets. They are
  kept in every total and band, and shown in their own band (RS3, RS8), because no approved
  rule removes them.
- **The above-10× band is concentrated in one entity.** Of the 227 OCIDs above ten times
  budget (₦1,540.1bn), the Federal Ministry of Works & Housing, headquarters, has 98 OCIDs
  worth ₦929.8bn (60.4% of the band's value), with a median ratio of 23.3×. The same entity
  accounts for all 65 snapshot tenders flagged DQ-05 (more than 1,000 tenderers), checked
  directly against `stg.tender`. A "budget recorded in thousands" explanation was tested
  (RS10) and not found: only 9 comparable OCIDs have an award within 10% of 1,000 times the
  budget (6 of them with a budget of ₦100,000 or more), against 227 OCIDs in the band. This
  describes a pattern only; no cause is attributed.

### 4.4 Procurement-cycle timing (M-E01, M-E02, signature lag)

| Measure | Eligible n | Coverage of candidate | Median | 90th percentile | Over 1 year |
|---|---|---|---|---|---|
| Tender open duration | 9,040 | 51.9% | 28 days | 64 days | 0.7% |
| Award lag (tender start → award) | 7,462 | 45.2% | 97 days | 267 days | 3.9% |
| Signature lag (award → signed) | 12,006 | 74.0% | 5 days | 62 days | 1.3% |

- **Date completeness limits every result.** Fewer than half the tenders can
  support an award lag. The results describe the processes that published valid
  dates; they say nothing about the rest.
- **By method.** Award lag is 9 days for Emergency, 43 for Selective
  Tendering, 112 for Direct Procurement and 120 for National Competitive
  Bidding.
- **By year.** Medians vary by year (tender duration 18 days in 2020, 42 in 2021).
  The analysis reports the pattern without attributing a cause.
- 3,826 signature lags are same-day (31.9%).

### 4.5 Procuring-entity benchmarking

- **Activity is concentrated.** Of 665 entities, the largest holds 40.6% of
  eligible award value, the top 10 hold 76.0% (but 26.9% of processes) and the
  top 100 hold 97.6%. The top quartile by value (65 entities) holds 94.8%.
- **Spread of KPIs** (entities above each minimum n): median single-bidder rate
  41.7% (103 entities), median top-supplier share 22.2% (173), median
  implementation coverage 99.1% (123), median tender reach 6.4% (373).
- **Ranks differ by measure.** An entity can be high on value yet low on
  process count (Federal Medical Centre, Taraba: 10 awards worth ₦175.8bn). RS3
  and RS4 show each entity's rank and percentile on every KPI beside its own n.

### 4.6 Implementation reporting coverage (M-I01, M-E03)

- **Coverage.** 14,140 of 16,221 contracts (87.2%) carry implementation data;
  78.9% have transactions and milestones, 8.3% milestones only, 12.8% none.
  Status matters little (active 86.9%) except pending (74.4%).
- **By entity** (123 entities with at least 20 contracts). 52 have full
  coverage; 47 more have 90% to under 100%; 6 have under half, one of them
  with none. The Federal Ministry of Works & Housing (headquarters, 1,677
  contracts) is at 21.6%. This is reporting coverage, not contract performance.
- **Lifecycle.** 82.3% of 98,454 OCIDs were published at planning stage only
  (DQ-02). Of OCIDs reaching the tender stage, 95.0% reach award; of those,
  98.2% reach contract; of those, 87.2% reach implementation.

### 4.7 Data-quality impact

- **Largest effects on the metrics:**
  - M-S01: DQ-14 (20.4% of candidate value excluded) and DQ-13 (34% of the
    eligible value sits with supplier IDs that have several name variants).
  - M-P01: DQ-06 extreme budgets are 32 lines but 50.8% of candidate budget
    value (₦96.4 trillion), so they would dominate any total.
  - M-V01: the single DQ-07 award is 23.3% of candidate award value.
  - M-E03, M-I01: DQ-02 (82% of OCIDs planning only); DQ-11 and DQ-12
    (79% of contracts have transactions without dates or reliable values).
- **DQ-20 (test entity).** Its footprint is 0.2% to 1.3% of the records in the seven
  metrics it touched, and 1.7% of the candidate award value. For M-C01/M-C02, M-E01 and
  M-E02 it is the largest footprint among the numbered issues (1.1% to 1.3% of records).
  It is removed before the candidate populations are defined.
- **Timing metrics lose the most records** (M-E01 48.1%, M-E02 54.9%, signature
  lag 26.0%), almost entirely to missing dates, not to numbered DQ issues
  (8,339 of M-E01's 8,365 exclusions). Chronology conflicts remove 135 award-lag
  and 734 signature-lag records.
- **Small footprints.** DQ-04, DQ-05, DQ-08, DQ-09, DQ-16, DQ-18, DQ-19 and the
  multi-project rule each touch under 2% of records in the metrics they affect.
- **Materiality** uses an analyst's reading rule (high 10%, moderate 1%; see
  the script header), confirmed by Kene on 2026-10-08. It is not a project rule and does not
  claim the data are wrong.

---

## 5. Decisions and Observations

**Decided on 2026-10-08 (Phase 8.1):**

| # | Item | Decision |
|---|---|---|
| D-1 | `TEST MINISTRY - NOCOPO` (`NG-BPP-BPP-NOC-90`) | Logged as DQ-20 (correction C-11): retained in `stg`/`core`, flagged, excluded from every analytical metric. No other test entity was found. |
| D-2 | `vw_dq_impact` | Counts as a validated analytical view for Gate C. |
| D-3 | Parameters | Minimum n of 10 awards, 30 tenders and 20 contracts, and the 10% / 1% materiality thresholds, are confirmed. |
| D-4 | Performance | Indexes first, then materialise the snapshot only if still slow. Done: see `phase8_1_dq20_and_performance.md`. |
| D-5 | Placeholder-like budgets (under ₦100,000, 16 OCIDs) | Known limitation, not excluded. |

**Observations still open:**

| # | Item | Status |
|---|---|---|
| O-1 | Values to verify against the source before use: the ₦210bn award behind the top supplier; Federal Medical Centre, Taraba (₦175.8bn from 10 awards); HADEJIA-JAMAĻARE RBDA, as spelled in the source (award ₦86.2bn against ₦4.0bn budget, ratio 21×). | Observed anomalies requiring further validation. Nothing is excluded. |

---

## 6. Reproduce

```bash
.venv/Scripts/python python/validation/05_run_analysis_scripts.py
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 8
```

The analytical layer (snapshot, indexes and all nine views) is rebuilt in the order given in
`docs/phase8_analysis/phase8_1_dq20_and_performance.md` §6; after any change to `stg.*` or
`core.dim_buyer`, refresh the materialised snapshot first with
`sql/04_transformations/04_refresh_snapshot.sql`.

A single script can be run with `psql -f sql/06_analysis/0N_*.sql` or with
`--only 0N`.

---

*Phase 8 log version 1.1 — 2026-10-08 (post-DQ-20 figures, Phase 8.1). Raw dataset not modified; no stg.* row changed.*
