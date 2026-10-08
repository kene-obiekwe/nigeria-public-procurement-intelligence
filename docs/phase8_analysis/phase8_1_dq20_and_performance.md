# Phase 8.1: DQ-20 Test-Entity Exclusion, Performance and Re-validation
# Nigeria Public Procurement Intelligence

> **Phase:** 8.1 — Corrections before Phase 9
> **Date:** 2026-10-08
> **Status:** Done. Gate B **107 / 107** (was 102), Phase 7 **27 / 27** (was 24), Phase 8 **31 / 31** (was 27); all GATE checks pass.
> **Approved by:** Project owner (DQ-20 for `NG-BPP-BPP-NOC-90`; indexes first, then materialise only if still slow).
> **Raw dataset:** not modified. **`stg.*` rows:** none changed or deleted.

---

## 1. Summary

1. The portal test entity `TEST MINISTRY - NOCOPO` (`NG-BPP-BPP-NOC-90`) is now logged as **DQ-20**
   (correction C-11). It is retained and flagged in `stg`/`core` and excluded from every
   `analytics.*` view, including the lifecycle counts, the entity benchmark and the
   candidate populations of `vw_dq_impact` and the register.
2. The analytical layer is fast enough for a BI refresh: every view returns in under 0.25 s
   (count) and the population register in about 3 s (was 38.5 s). `vw_dq_impact` takes
   about 3 to 5 s (was 43.4 s).
3. Budget-to-award findings carry the two requested clarifications (placeholder-like budgets;
   the above-10× band) with SQL result sets behind them (script 03, RS8 to RS10).
4. All three suites and the analysis runner were re-run. Populations changed by 0.2% to 1.5%.

---

## 2. Test-Data Scan

Scope: `core.dim_buyer` (667 IDs) and `core.dim_supplier` (10,325 IDs), plus `stg.parties` names.
Method: case-insensitive match on the **whole words** test, tests, testing, demo, dummy, sample,
trial, nocopo, fake in the ID and in both the raw and standardised names. A looser substring
match was run first to be sure nothing was missed.

| Result | Candidate | Releases / records | Value | Verdict |
|---|---|---|---|---|
| Whole-word match, buyers | `NG-BPP-BPP-NOC-90` TEST MINISTRY - NOCOPO | 427 releases, 412 OCIDs; 188 snapshot awards (183 active and valid), 396 budget lines, 171 contracts | awards NGN 72.8bn (all statuses), NGN 72.0bn eligible; budget lines NGN 529.7bn | **Pre-approved: DQ-20** |
| Whole-word match, suppliers | none | 0 | — | — |
| Whole-word match, `stg.parties` | only `NG-BPP-BPP-NOC-90` | — | — | — |
| Substring match only (buyers) | INDUSTRIAL TRAINING FUND; FEDERAL INSTITUTE OF INDUSTRIAL RESEARCH -OSHODI | 519 and 472 releases | — | Ordinary words ("INDUSTRIAL" contains "trial"). Not test data. |
| Substring match only (suppliers) | 16 names, for example TESTIMONY, TESTED ENGINEERING, TESTLIM LAWAL ASSOCIATES, ESTEEM DEMONSTARTION INT'L, Samob Agric and Industrial, Bytestrems Consulting | 1 name variant each (one has 2) | — | Ordinary company names that contain the letters. Not treated as test data; none excluded. |

No other test or dummy entity was found, so the stop condition did not apply. Gate B check EN-19
keeps this scan as a guard: it fails if another buyer with such a whole word appears after a
data refresh.

---

## 3. DQ-20 Implementation

| Layer | Change |
|---|---|
| Decision log | `phase3_data_quality_decision_log.md` v1.4: issue DQ-20, summary-matrix row, flag row |
| Correction log | `phase3_2_correction_log.md` v1.3: correction C-11 |
| Schema | `core.dim_buyer.test_entity_flag` (generated from the buyer ID: `TEST_ENTITY` for `NG-BPP-BPP-NOC-90`, else NULL) with a CHECK constraint. DDL v1.4 in `00_draft_core_schema.sql`; existing databases apply `01_migration_v1_4.sql` |
| Staging / core data | Unchanged. All 427 releases stay in `stg.releases`; the buyer stays in `core.dim_buyer` and its 412 OCIDs in `core.vw_process_snapshot` (checks EN-15 to EN-18, AV-20) |
| Analytics | `test_entity_flag IS NULL` added to every view in `sql/05_views/01` to `07`; `08_metric_population` and `09_dq_impact` define their candidate populations without it |
| `vw_dq_impact` | DQ-20 appears as one `PRE_EXCLUDED` row per metric; it is outside `candidate − eligible` |
| Validation | Gate B EN-15 to EN-19; Phase 7 AV-19 to AV-21 (AV-22 INFO) and independent recounts that drop the test entity first; Phase 8 DQI-16 to DQI-19 |

The rule is by buyer ID, not by name, so it is explicit and auditable. Other test records
published under a real buyer's ID, if any, cannot be detected.

---

## 4. Before and After Populations

Before = first Phase 7/8 run; after = current (`analytics.vw_metric_population`).

| Metric | Candidate before | Candidate after | Eligible before | Eligible after | Eligible % before → after |
|---|---|---|---|---|---|
| M-P01 | 97,749 | 97,353 | 97,196 | 96,802 | 99.4 → 99.4 |
| M-C01 / M-C02 (primary) | 17,623 | 17,405 | 17,469 | 17,253 | 99.1 → 99.1 |
| M-C01 (sensitivity) | 17,623 | 17,405 | 17,482 | 17,266 | 99.2 → 99.2 |
| M-V01 | 16,715 | 16,527 | 15,946 | 15,763 | 95.4 → 95.4 |
| M-S01 | 15,946 | 15,763 | 13,694 | 13,537 | 85.9 → 85.9 |
| Budget-to-award | 15,946 | 15,763 | 15,753 | 15,574 | 98.8 → 98.8 |
| M-E01 | 17,623 | 17,405 | 9,180 | 9,040 | 52.1 → 51.9 |
| M-E02 | 16,715 | 16,527 | 7,569 | 7,462 | 45.3 → 45.2 |
| Signature lag | 16,392 | 16,221 | 12,138 | 12,006 | 74.0 → 74.0 |
| M-E03 | 98,866 | 98,454 | 98,866 | 98,454 | 100.0 → 100.0 |
| M-I01 | 16,392 | 16,221 | 16,392 | 16,221 | 100.0 → 100.0 |
| Entity benchmark | 667 | 666 | 666 | 665 | 99.9 → 99.8 |

The 412 OCIDs removed from M-E03 equal the test entity's OCIDs (AV-13, AV-20). The
`stg.releases` and `core.vw_process_snapshot` row counts are unchanged (108,277 and 98,866).

### Effect on headline results

| Result | Before | After |
|---|---|---|
| M-S01 excluded for bare `NG-BPP-` supplier ID | 2,252 awards; ₦675.8bn; 20.1% | 2,226 awards; ₦670.4bn; 20.4% |
| M-S01 top supplier / top 10 share | 7.83% / 28.54% | 8.03% / 29.0% |
| Herfindahl index (M-S01) | 134.8 | 139.4 |
| Single-bidder rate (M-C02) | 43.97% | 44.04% |
| Median award lag (M-E02) | 94 days | 97 days |
| Median tender duration; signature lag | 28; 5 days | 28; 5 days |
| Budget-to-award aggregate / median ratio | 0.2514 / 0.9304 | 0.2486 / 0.9298 |
| Implementation coverage (M-I01) | 87.26% | 87.17% |
| Award before tender; signed before award (process level) | 141; 756 | 135; 734 |

The largest shift in a headline median is M-E02 (award lag 94 to 97 days). No conclusion changed.

---

## 5. Performance

Method: `count(*)` over each view, median of 3 runs, PostgreSQL 17.4, default `work_mem` (4 MB) and
`shared_buffers` (128 MB), no configuration change. "Full fetch" is `SELECT *` fetched in Python.

| View | Rows before | Rows after | Before | After (count) | After (full fetch) |
|---|---|---|---|---|---|
| `core.vw_budget_lines` | 97,749 | 97,749 | 0.5 s | 0.01 s | 0.26 s |
| `core.vw_process_snapshot` | 98,866 | 98,866 | 0.4 s | 0.01 s | 0.18 s |
| `analytics.vw_budget_eligible` | 97,196 | 96,802 | 1.9 s | 0.12 s | 0.50 s |
| `analytics.vw_competition_eligible` | 17,482 | 17,266 | 1.9 s | 0.10 s | 0.17 s |
| `analytics.vw_award_value_eligible` | 15,946 | 15,763 | 2.1 s | 0.07 s | 0.34 s |
| `analytics.vw_supplier_award_eligible` | 13,694 | 13,537 | 2.1 s | 0.21 s | 0.50 s |
| `analytics.vw_budget_award_comparison` | 15,753 | 15,574 | 5.1 s | 0.16 s | 0.50 s |
| `analytics.vw_tender_duration_eligible` | 9,180 | 9,040 | 2.0 s | 0.05 s | 0.10 s |
| `analytics.vw_award_lag_eligible` | 7,569 | 7,462 | 1.9 s | 0.22 s | 0.33 s |
| `analytics.vw_signature_lag_eligible` | 12,138 | 12,006 | 2.0 s | 0.13 s | 0.12 s |
| `analytics.vw_lifecycle_stage` | 98,866 | 98,454 | 1.9 s | 0.05 s | 0.35 s |
| `analytics.vw_contract_implementation_coverage` | 16,392 | 16,221 | 1.9 s | 0.05 s | 0.23 s |
| `analytics.vw_entity_benchmark` | 666 | 665 | 2.0 s | 0.08 s | 1.18 s |
| `analytics.vw_metric_population` | 12 | 12 | 38.5 s | 2.62 s | 2.58 s |
| `analytics.vw_dq_impact` | 40 | 47 | 43.4 s | 4.48 s | 4.64 s |

Target was under 5 s for each, and all views meet it on their median. `vw_dq_impact` varies
between about 3 s and 5.5 s from run to run on this machine (median 4.5 s to 4.6 s); it is the
one to watch if the dashboard refresh is ever frequent.

### What produced the gain (measured in this order)

| Step | Register | `vw_dq_impact` | Note |
|---|---|---|---|
| Baseline | 38.5 s | 43.4 s | |
| a. Index `stg.releases (ocid, release_seq DESC) INCLUDE (release_id, buyer_id)` | 22.2 s | 27.4 s | Each "latest release" step sorted all 108,277 releases and spilled to disk at the default `work_mem`. `vw_lifecycle_stage` fell from 1.9 s to 0.7 s. |
| b. Materialise `core.vw_budget_lines` and `core.vw_process_snapshot`, with indexes | 7.0 s | 8.8 s | Still above 5 s after step a, so step b was required by the task rule. Views now read stored rows. |
| c. `ANALYZE` the materialised views | 1.5 s to 2.6 s | 3.3 s to 5.1 s | Without statistics the planner chose nested loops: `vw_budget_eligible` took 1.7 s and 0.2 s afterwards. `ANALYZE` is now part of the build and refresh scripts. |

Refresh cost: `REFRESH MATERIALIZED VIEW` of both takes about 5 s (5.3 s with the index, 6.1 s
without), so the index mainly helped before materialisation. It is kept because the measured
plans justified it and it speeds the refresh.

Other candidate indexes (`stg.contracts`, `stg.milestones`, `stg.transactions`, `stg.planning`) were
not added: after steps a to c no view took more than 0.25 s (count), so no measured plan justified them.

**Operational note.** The materialised views hold a snapshot of `stg`. If `stg.*` or
`core.dim_buyer` is rebuilt without running `04_refresh_snapshot.sql`, the analytics views
return stale figures. The refresh is part of the build sequence below.

---

## 6. Build and Refresh Sequence

**Fresh database** (everything from the raw file):

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/02_schema/00_draft_core_schema.sql
```

```bash
.venv/Scripts/python python/ingest/01_load_staging.py
```

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/02_schema/02_performance_indexes.sql -f sql/04_transformations/01_build_dim_buyer.sql -f sql/04_transformations/02_build_dim_supplier.sql -f sql/04_transformations/03_process_snapshot.sql
```

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/01_budget_eligible.sql -f sql/05_views/02_competition_eligible.sql -f sql/05_views/03_award_and_supplier_eligible.sql -f sql/05_views/04_budget_award_comparison.sql -f sql/05_views/05_timing_eligible.sql -f sql/05_views/06_lifecycle_and_implementation.sql -f sql/05_views/07_entity_benchmark.sql -f sql/05_views/08_metric_population.sql -f sql/05_views/09_dq_impact.sql
```

**Existing database built before Phase 8.1** (what was run here):

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/02_schema/01_migration_v1_4.sql -f sql/02_schema/02_performance_indexes.sql -f sql/02_schema/03_migration_v1_4_materialise_snapshot.sql -f sql/04_transformations/03_process_snapshot.sql
```

then the `sql/05_views` command above. The migration drops the old plain snapshot views
and, with them, every `analytics.*` view (`DROP VIEW ... CASCADE`); all thirteen are recreated by
the `05_views` files, and the suites confirm it.

**After any change to `stg.*` or `core.dim_buyer`:**

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/04_transformations/04_refresh_snapshot.sql
```

**Validate and regenerate results:**

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 6
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 7
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 8
```

```bash
.venv/Scripts/python python/validation/05_run_analysis_scripts.py
```

---

## 7. Validation

| Suite | Before | After | Notes |
|---|---|---|---|
| Gate B (`--phase 6`) | 102 / 102 | **107 / 107** (stage 1: 64 / 64) | EN-15 to EN-19 added. The original 102 checks pass unchanged. |
| Phase 7 (`--phase 7`) | 24 / 24 | **27 / 27** | AV-01 to AV-18 recounts now drop the test entity first and match; AV-19 to AV-21 added. |
| Phase 8 (`--phase 8`) | 27 / 27 | **31 / 31** | BQ recounts and DQI checks updated; DQI-16 to DQI-19 added. |
| Analysis runner | 7 scripts | 7 scripts, 50 result sets, no failures | Script 03 gains RS8 to RS10. Materialisation broke no script. |
| Fresh build | — | **Reproduced** | The §6 fresh sequence was run on an empty scratch database (DDL, staging load, dimensions, snapshot, nine views): Phase 7 27 / 27, Phase 8 31 / 31, and the population register is identical to the main database. The scratch database was then dropped. |

---

## 8. Issues and Lessons

- **Estimates matter more than indexes.** A first version of the Phase 7 recount used a
  `row_number() ... WHERE rn = 1` CTE to find each OCID's buyer. The planner estimated 541 rows
  instead of 98,866 and the suite ran for over 20 minutes. Using `DISTINCT ON` fixed it (12 s).
  Separately, the materialised views needed `ANALYZE` (§5, step c).
- **Staleness risk** of materialised views is the cost of the speed-up (§5).
- **`vw_dq_impact`** still reads `core`/`stg` by design; it is validated (DQI checks) and approved
  as a validated view for Gate C.
- **Regenerated timestamps.** Running Gate B also regenerates the Phase 5 results file, whose only
  change is the run date; that file was left as it was.

---

*Phase 8.1 log version 1.0 — 2026-10-08. Raw dataset not modified; no stg.* row changed.*
