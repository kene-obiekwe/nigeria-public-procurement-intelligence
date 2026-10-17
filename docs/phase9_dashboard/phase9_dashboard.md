# Phase 9: Power BI Data Model, DAX Blueprint and Reconciliation Pack
# Nigeria Public Procurement Intelligence

> **Phase:** 9 — Power BI Dashboard Development
> **Date:** 2026-10-08 (blueprint); 2026-10-17 (build, reconciliation and packaging)
> **Status:** Complete. The report is built (8 pages), all 177 figures reconcile with SQL, and the template, screenshots and usage note are delivered.
> **Phase 9 validation: 16 / 16 GATE checks passed** (1 INFO). Gate B 107 / 107, Phase 7 27 / 27 and
> Phase 8 31 / 31 re-confirmed.
> **Phase 9 exit gate:** every figure reconciles with its SQL source: **177 / 177** (`dashboard/reconciliation_log.md`).
> Gate D (findings trace to SQL) is Phase 10.
> **Validation log:** `docs/phase9_dashboard/phase9_validation_results.md`
> (`python/validation/04_run_validation_suite.py --phase 9`)

---

## 1. What was delivered

| Deliverable | Path | Purpose |
|---|---|---|
| Read-only BI role | `database/seed_and_setup/01_create_bi_role.sql` | `nocopo_bi`: CONNECT, USAGE and SELECT on `analytics` only. No password in any file |
| Role test | `database/seed_and_setup/02_test_bi_role.sql` | Shows SELECT on `analytics.*` succeeds and `stg`, `core`, writes and DDL are refused |
| Presentation dimensions | `sql/05_views/10_dim_views.sql` | `analytics.vw_dim_buyer` (665), `analytics.vw_dim_procurement_method` (11) |
| Validation | `sql/03_data_quality/11_bi_layer_checks.sql` | BI-01 to BI-05 (role), DIM-01 to DIM-12 (dimensions) |
| Blueprint | `dashboard/README.md` | Connection, model, DAX, layout, caveats, reconciliation procedure |
| Expected values | `dashboard/reconciliation_expected_values.sql` | One read-only query, 177 figures with eligible n |
| Reconciliation log | `dashboard/reconciliation_log.md` | 177 figures, SQL value and dashboard value, all matching; page sign-off table |
| Log generator | `python/validation/06_generate_reconciliation_log.py` | Builds the log; refuses to overwrite sign-offs |
| Power Query scripts | `dashboard/power_query_m.md` | M script for each of the 15 tables |
| Report template | `dashboard/NOCOPO_Dashboard.pbit` | Model, measures and 8 pages; no data, no credentials. The `.pbix` is not committed |
| Screenshots | `dashboard/screenshots/` | One 1920 x 1080 image per page, slicers cleared |
| Usage note | `dashboard/USAGE.md` | Opening, reading and limitations |

---

## 2. Gate C, enforced

Gate C says Power BI must connect only to validated analytical views. Convention is not enough, so the database enforces it:

- `nocopo_bi` is `LOGIN` without a password (the owner sets it with `\password nocopo_bi`), not a superuser, and
  cannot create databases, roles or objects. Sessions are read-only and limited to 120 s per statement.
- It holds `USAGE` on `analytics` and `SELECT` on every object there, and nothing on `stg` or `core`.
- Test results (`02_test_bi_role.sql`, run as the owner with `SET ROLE nocopo_bi`):

| Attempt | Result |
|---|---|
| `SELECT` from `analytics.vw_metric_population` (12), `vw_dim_buyer` (665), `vw_budget_eligible` (96,802), `vw_dq_impact` (47) | rows returned |
| `SELECT` from `stg.releases`, `stg.awards` | `permission denied for schema stg` |
| `SELECT` from `core.dim_buyer`, `core.vw_process_snapshot` | `permission denied for schema core` |
| `DELETE` / `INSERT` on `analytics.vw_dim_buyer` | `permission denied for view vw_dim_buyer` |
| `CREATE TABLE` in `analytics` or `public` | `permission denied for schema` |
| Objects outside `analytics` the role can read | 0 |

`04_run_validation_suite.py --phase 9` repeats this on every run (BI-01 to BI-05), so a later change that widens the role
fails the suite. `pg_hba.conf` requires `scram-sha-256` on localhost, so the role cannot log in until a password is set.

---

## 3. Design decisions

| # | Decision | Reason |
|---|---|---|
| P-1 | Import mode | Small data (about 300,000 rows), full DAX medians and percentiles, and a stored snapshot of validated data. See `dashboard/README.md` §3 |
| P-2 | Two presentation dimensions only | One buyer and one method slicer drive every page. `vw_dim_buyer` keys on `buyer_id` and adds `buyer_label`, because four names are shared by two IDs (not merged) |
| P-3 | The bare `NG-BPP-` buyer is not in the buyer dimension | It is not an entity (DQ-19). Its 98 fact rows count in totals and show as (Blank) when split by buyer |
| P-4 | Procurement method: NULL becomes the label `(method not stated)` in Power Query | A label so the relationship matches; the dimension has an explicit row for it. The fact views are unchanged |
| P-5 | Presentation bins (participation, ratio, duration, implementation type) are DAX calculated columns | Thresholds duplicate SQL on purpose and are guarded by band-count figures COM-B, BVA-B, TIM-D, IMP-T |
| P-6 | Materiality ratings are not recomputed in DAX | They depend on candidate value and several rules; they stay a SQL-script output (script 07) |
| P-7 | Entity KPIs are read from `vw_entity_benchmark`, never re-aggregated | They are precomputed medians and rates per entity |
| P-8 | The M-S01 disclosure is a measure | It reads excluded awards and value from the data (`Awards` minus `Suppliers`) and cross-checks against `vw_dq_impact` (DQ-14). Nothing is typed in |
| P-9 | Reconciliation pack of 177 figures | Covers every card and band the blueprint defines, with eligible n; generated into a log that is not overwritten once signed |
| P-10 | No shared date dimension (decided by Kene, 2026-10-14) | Event dates are too sparse across the analytical views. Time analysis is limited to awards (`Award Year`) and the three timing views (`Tender Start Year`, `Award Year`, `Signed Year`). Recorded as a known limitation (`dashboard/README.md` §10) |
| P-11 | Package a `.pbit` template and page screenshots; the `.pbix` is gitignored and never committed (decided by Kene, 2026-10-14) | The `.pbix` holds imported data. The template carries the model and report without data |
| P-12 | `Supplier Rank`, `Supplier Share` and `Cumulative Supplier Share` redefined to use `ALL` on `supplier_id` and `supplier_name`; top-20 table limited by a rank filter (decided by Kene, 2026-10-15) | The README form gave rank 1 and 100% share on every row when both columns are in the table, and `ALLSELECTED` also sees the top-20 filter (shares came out relative to the top-20 total). Checked against SUP-04 and SUP-07 |

No KPI required re-implementing SQL eligibility, deduplication or data-quality exclusion logic in DAX, so the stop condition did not apply.

---

## 4. Findings to carry forward

1. **No date column** in the competition, budget, lifecycle, implementation and entity views. Time-period slicing is
   available only for awards and the three timing metrics. A shared date dimension would need valid date columns added in SQL.
   This is a gap, not a blocker for the agreed pages.
2. **Procurement method** is the only category-like field.
3. **Built and tested in Power BI Desktop** (September 2026 release). The first build exposed one measure defect, fixed with
   the owner's approval (decision P-12): `Supplier Rank`, `Supplier Share` and `Cumulative Supplier Share` as first written gave
   rank 1 and 100% on every row of the top-20 table. Every other measure matched its expected value as written.
4. **Ties in `TOPN`.** Supplier values are not tied at the reconciled cut-offs (ranks 1, 5, 10, 20, 100); other cut-offs can
   include extra tied suppliers.

---

## 5. Reproduce

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/10_dim_views.sql -f database/seed_and_setup/01_create_bi_role.sql
```

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -f database/seed_and_setup/02_test_bi_role.sql
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 9
```

```bash
.venv/Scripts/python python/validation/06_generate_reconciliation_log.py
```

Then follow `dashboard/README.md` to build the report and complete the log (`dashboard/USAGE.md` describes the finished report).

---

## 6. Build outcome

| Item | Result |
|---|---|
| Tables, relationships | 15 tables, 17 relationships, 7 helper tables, 16 calculated columns; auto date/time off |
| Measures | About 90, each with an eligible-n companion; checked against `reconciliation_expected_values.sql` |
| Pages | 1, 2a, 2b, 3, 4, 5, 6, 7 (README page 2 was split into 2a and 2b; page 4 timing, 5 entity, 6 implementation, 7 data quality as in README §7) |
| Reconciliation | 177 / 177. Dashboard values were obtained by evaluating each measure in the model with the figure's slice; one row (IMP-T3) is blank in the model where SQL gives 0, because no contract falls in that group |
| Deviations from README §7 | Entity highest/lowest tables show 4 to 8 rows (page space; ties are all listed); page 4 shows the timing caveat as static text, not the dynamic measure, and no small-n label (n is shown in the table); page 7 uses a table, not a matrix; the "largest absolute variance" table is two tables (largest positive, largest negative) |
| Decisions recorded | P-10 (no shared date dimension), P-11 (`.pbit` template and screenshots, no `.pbix`), P-12 (supplier ranking measures) |
| Model change | Only the three supplier ranking measures (P-12) |

### Items left for Phase 12 (final QA)

| Item | Detail |
|---|---|
| Template on a second computer | `dashboard/NOCOPO_Dashboard.pbit` was exported from the finished report. Opening it on another computer, signing in as `nocopo_bi` and refreshing has not been tested |
| Header wrap, page 5 | In the entity KPI table the header "Implementation coverage" breaks mid-word in the screenshot (`05_entity_benchmark.png`). Cosmetic; fixing it means widening that column, re-exporting and re-capturing the screenshot |

---

*Phase 9 log version 1.0 — 2026-10-08. Raw dataset not modified; no stg.* or core.* object changed.*
