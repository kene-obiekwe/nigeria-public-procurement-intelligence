# Phase 10.1: Correction Pass (C-12 and DQ-21 / C-13)
# Nigeria Public Procurement Intelligence

> **Phase:** 10.1 — Correction pass after the Phase 10 source checks
> **Date:** 2026-10-17
> **Approved by:** Project owner (both proposals in `findings.md` §13; DQ-21 rule A chosen after the size check)
> **Status:** Applied. **Phase 10.1 validation: 14 / 14 GATE checks passed** (3 INFO). Gate B 107 / 107, Phase 7 27 / 27,
> Phase 8 31 / 31 and Phase 9 16 / 16 re-run with unchanged expected values. Reconciliation pack: 177 / 177 figures
> identical. Findings trace check (`07_check_findings_trace.py --live`): pass.
> **Validation log:** `docs/phase10_findings/phase10_validation_results.md`
> (`python/validation/04_run_validation_suite.py --phase 10`)

---

## 1. C-12: release-date statements (documentation only)

Earlier documents said every release carries the date `2021-05-03T22:44:00Z`. That is the package `publishedDate`.
Release dates run from 2021-05-03 to 2026-07-29 (9,786 distinct values; 786 releases carry the package date).
Corrected in DQ-10, the data dictionary, both Phase 2 reports (dated notes, original text kept), the Phase 4 model,
`data/README.md`, the README audit table, and comment or message text in the schema, snapshot and loader files.
The DQ-10 rule stands and no figure changes: no metric uses the release date, and integer release order agrees with
release date in every multi-release OCID. The DQ-09 FUTURE class was re-checked against the new date range: none of
the event dates it flags falls on or before the last release date. Details: `phase3_2_correction_log.md` C-12.

---

## 2. DQ-21: possible award scale errors (flag and sensitivity, no exclusion)

### 2.1 Rule

`analytics.vw_award_scale_flag` (`sql/05_views/11_award_scale_flag.sql`) lists M-V01 eligible awards that pass
either test, one row per award, `scale_flag = POSSIBLE_SCALE_ERROR`:

| Test | Condition | Comparator |
|---|---|---|
| DROPPED_DECIMAL | Whole-naira award, award / budget between 50 and 200 (award / 100 within a factor of two of the budget) | The OCID's single budget line (budget-to-award population) |
| SIBLING_LOT | Award at least 500 times the same supplier's largest other eligible award from the same buyer | Same supplier ID and complete buyer ID (DQ-19 bare buyer not matched) |

No existing view, metric, result set or dashboard measure reads the flag.

### 2.2 Size (reported before wiring; stop threshold exceeded, owner chose rule A)

| Measure | Value |
|---|---|
| Flagged awards | 45 (39 DROPPED_DECIMAL, 6 SIBLING_LOT, none both), 31 entities |
| Flagged value | NGN 509.5bn, 15.5% of M-V01 eligible award value |
| Largest single flagged award | NGN 210.08bn (SIBLING_LOT; `source_verification.md` §A), 41% of the flagged value |
| Alternative considered | DROPPED_DECIMAL at 90 to 110 times budget only: 30 awards, 10.4% of value (not chosen) |
| Not flagged, documented | FMC Taraba NGN 174.0bn award: no budget line and no usable supplier ID, so neither test applies (`source_verification.md` §B) |

### 2.3 Sensitivity (new result sets; existing ones unchanged)

| Measure | As published | Without flagged awards | Source |
|---|---|---|---|
| Top-1 supplier share (M-S01) | 8.03% | 5.22% | 01 RS6 |
| Top-10 supplier share | 29.00% | 26.13% | 01 RS6 |
| Herfindahl index | 139.4 | 101.3 | 01 RS6 |
| Emergency: top-1 supplier share | 61.4% | 55.3% | 01 RS6b |
| Aggregate award-to-budget ratio | 0.2486 | 0.2080 | 03 RS11 |
| Median award-to-budget ratio | 0.9298 | 0.9285 | 03 RS11 |
| Processes above ten times budget | 227 (49.82% of compared value) | 186 (39.93%) | 03 RS11 |
| Largest entity's share of award value | 40.6% | 47.1% | 05 RS7 |
| Ten largest entities' share | 76.0% | 76.2% | 05 RS7 |

Reading: medians are robust; the top-supplier share, the Herfindahl index and the above-ten-times group depend
materially on the flagged awards. Emergency procurement stays the most concentrated method either way.

### 2.4 Validation

`sql/03_data_quality/12_award_scale_flag_checks.sql`, run with `04_run_validation_suite.py --phase 10`:

- SF-01 to SF-03: the view matches an independent recount of each test (45 = 39 + 6).
- SF-04 to SF-10: one row per award; all inside the M-V01 population; no DQ-07 EXTREME award (EXTREME awards are
  outside M-V01 by definition, so overlap is impossible) and no DQ-20 award; every row satisfies its test; no sibling
  match on the bare buyer.
- SF-11 to SF-13: spot checks on the raw-source items (A flagged SIBLING_LOT; the exact ×100 award flagged
  DROPPED_DECIMAL; FMC Taraba not flagged).
- SF-14: M-V01, M-S01 and budget-to-award eligible counts unchanged (15,763; 13,537; 15,574).

Regression: the Phase 6–9 suites pass with unchanged expected values; in `phase8_analysis_results.md` every
pre-existing result set is identical (only run timings changed); the 177-figure reconciliation pack returns the
values in the signed log. The dashboard is unchanged and needs no re-signing.

---

## 3. Reproduce

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/11_award_scale_flag.sql
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 10
```

```bash
.venv/Scripts/python python/validation/05_run_analysis_scripts.py
```

```bash
.venv/Scripts/python python/validation/07_check_findings_trace.py --live
```

---

*Phase 10.1 log version 1.0 — 2026-10-17. Raw dataset not modified; no stg.* or core.* object changed; one analytics view added.*
