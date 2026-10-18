# Phase 12 QA Checklist
# Nigeria Public Procurement Intelligence

> **Phase:** 12 — Final QA, Reconciliation & Review
> **Date:** 2026-10-18
> **Commit reviewed:** `dceaac8` (with the README edit `42bf3ad`)
> **Result:** **PASS.** The clean rebuild reproduces every committed result; no defect was found that needs a change to
> SQL, findings or the dashboard. Open items are listed in §8.
> **Sign-off note:** [`signoff_note.md`](signoff_note.md)

---

## 1. Clean rebuild

`python/run_pipeline.py --db nocopo_qa --create-db` against a new, empty database, from the pinned source file.

| Step | Result | Time |
|---|---|---|
| schema, staging load (SHA-256 checked before and after), core, snapshot refresh, analytics views, BI role, `ANALYZE` | ok | 159 s |
| Raw → staging reconciliation (stage 1 of `--phase 6`) | 64 / 64 | — |
| `--phase 6` Gate B | 107 / 107 GATE | 14 s |
| `--phase 7` analytical views | 27 / 27 GATE | 10 s |
| `--phase 8` business-question outputs | 31 / 31 GATE | 12 s |
| `--phase 9` read-only BI role and dimensions | 16 / 16 GATE | 10 s |
| `--phase 10` DQ-21 scale flag | 14 / 14 GATE | 4 s |
| Analysis scripts (7 scripts) | ok | 52 s |
| Findings trace check `--live` | pass | 12 s |
| **Total** | **all 14 steps passed** | **274 s** |

**Comparison with the committed outputs.** The eight regenerated result logs (Phase 5 to Phase 10.1 validation logs,
`phase8_analysis_results.md`, `claim_trace_check_results.md`) were diffed against `HEAD`. Every changed line is run
metadata: run dates, the database name (`nocopo_qa`) and result-set timings. No value, count, check or result set
differs. The scratch database was dropped and the committed logs restored afterwards.

---

## 2. Dashboard

| Check | Result | Evidence |
|---|---|---|
| `dashboard/reconciliation_expected_values.sql` on the rebuilt database returns the values in the signed log | **177 / 177 identical**, 0 mismatches | compared with every SQL value in [`../../dashboard/reconciliation_log.md`](../../dashboard/reconciliation_log.md) |
| Committed `.pbit` is the Phase 11B version | yes: last changed in `dceaac8` | `git log -- dashboard/NOCOPO_Dashboard.pbit` |
| No imported data in the template | no `DataModel` part; only `DataModelSchema` (metadata) | archive listing of the `.pbit` |
| No secrets or local paths | no password, token or key strings and no user paths in any text part; the only connection is `PostgreSQL.Database("localhost:5433", "nocopo_db")` | text scan of every part |
| C-12 footer wording | present (package metadata dated 2021-05-03, releases dated to 2026-07-29, SHA-256); the old "source file published 2021-05-03" wording is absent | text scan of the visuals |
| `SecurityBindings` part | an encrypted binary part that Power BI files carry; it cannot be read here. Power BI templates do not save data-source credentials; opening the template on a second machine confirms it (item OI-09) | — |

---

## 3. Business-question walkthrough

Each headline in the README and findings resolves through its claim tag to a result set of the current SQL. The
rebuild's trace check compared every claim-trace row with the result sets regenerated on `nocopo_qa`: all 236 matched.

| Question | Headline as published | Claim tags | Source result sets |
|---|---|---|---|
| 1 Supplier concentration | The top ten suppliers hold 29.0% of attributable value; 2,226 awards (₦670.4bn, 20.4% of eligible award value) lack a usable supplier ID; Emergency top supplier 61.4%, and 26.1% / 55.3% without the flagged awards | [S1] [S2] [S4] [S6] | script 01: RS1, RS2, RS4, RS6, RS6b |
| 2 Competition | 44.0% of 17,253 tenders record one tenderer; 39.6% of 10,129 under National Competitive Bidding | [C1] [C3] | script 02: RS1, RS4 |
| 3 Budget versus award | Median ratio 0.93 over 15,574 processes; 227 processes above ten times budget hold 49.8% of compared value, 39.9% without the flagged awards | [B1] [B3] [B8] | script 03: RS1, RS3, RS11 |
| 4 Cycle timing | Median award lag 97 days; only 45.2% of candidates publish the dates it needs | [T1] [T2] | script 04: RS1, RS1b |
| 5 Entity benchmarking | The largest entity holds 40.6% of award value and the ten largest 76.0%; 47.1% without the flagged awards | [E2] [E7] | script 05: RS2, RS7 |
| 6 Implementation coverage | 87.2% of 16,221 contracts carry implementation data (a reporting signal) | [I1] | script 06: RS1 |
| 7 Data-quality impact | 82.3% of processes are planning-only; 45 awards (₦509.5bn, 15.5% of eligible award value) flagged as possible scale errors | [Q1] [X1] | script 07: RS2; script 03: RS11a |

Every question in the scope has a script, a findings section and traced figures; none is left unanswered.

---

## 4. Cleaning anti-patterns (Data-Quality Plan §16)

| Anti-pattern | Verdict | Evidence |
|---|---|---|
| Dropping every row containing a NULL | Not done | No `DELETE` or `UPDATE` on data anywhere in `sql/` or `python/` (the only `DELETE` is in `database/seed_and_setup/02_test_bi_role.sql`, which proves the read-only role is refused). `TRUNCATE` appears only where a table is rebuilt in full (staging reload, `core.dim_*`). Staging reconciles to the raw file 64 / 64. |
| Replacing missing monetary values with zero | Not done | No source amount is coalesced to zero. `coalesce(…, 0)` occurs only for counts of absent child records (transactions, milestones, eligible n) and for entity totals in share and rank denominators, where an entity with no eligible awards contributes nothing; `vw_entity_benchmark` keeps NULL ("no eligible records"). Zero amounts are flagged `ZERO_VALUE` and excluded from value metrics (DQ-16). |
| Replacing missing tenderer counts with zero | Not done | `vw_competition_eligible` uses `number_of_tenderers` as published (no null in the snapshot population); counts above 1,000 are excluded, 101–1,000 kept for sensitivity (DQ-04, DQ-05). |
| Mean or median imputation of financial values | Not done | No imputation code in `sql/` or `python/` (no `fillna`, `interpolate` or imputed `coalesce`); medians are only reported. |
| Removing outliers by an IQR / z-score rule | Not done | No `stddev`, IQR or percentile filter in `sql/`; extremes are excluded only by documented issues (DQ-06, DQ-07), and suspected scale errors are flagged, not removed (DQ-21). |
| Merging suppliers on name similarity | Not done | No fuzzy, trigram or similarity matching in code; `core.dim_supplier` is keyed on source ID; canonical mapping deferred (DQ-15). |
| Dropping repeated records without understanding release history | Not done | No `drop_duplicates` anywhere. Repeated releases are kept in `stg`; the section-level snapshot (integer release order) was validated against the raw data before adoption ([Phase 4.1 evidence](../phase4_data_model/phase4_1_snapshot_validation_report.md)). |
| Changing source values directly | Not done | The raw file is read-only and SHA-256 checked before and after the load; staging stores values as published and data-quality flags are generated columns. |
| Cleaning to make a conclusion stronger | Not done | DQ-21 is reported with sensitivity results that weaken some headlines (findings §3, §5, §7); exclusions are attributed in `vw_dq_impact`. |
| Using cleaned data without explaining what changed | Not done | Decision log DQ-01 to DQ-21, correction logs C-01 to C-13, `vw_metric_population` and `vw_dq_impact`. |

**Risk watch-list (Implementation Plan §8)**: tables designed before the audit (no: Gate A, schema after the Phase 3
log); repeated identifiers treated as duplicates (no, as above); Power BI as a second transformation layer (no: see
§5); zero imputation (no); name-based merging (no); metrics without their population (no: every metric carries its n,
`vw_metric_population`); missing implementation read as non-performance (no: L-18); scope creep (no: every view and
page serves one of the seven questions).

---

## 5. Technology non-goals (Architecture §15)

| Non-goal | Verdict | Evidence |
|---|---|---|
| No cloud for appearance | Met | Local PostgreSQL only; no cloud configuration in the repository |
| No Python for core analytics | Met | Python loads, runs and checks; the analysis runner refuses any script that reads `stg`/`core` or contains DDL/DML; every metric is a SQL view |
| No unnecessary duplication of SQL logic in DAX | Met | Only three documented constant duplicates (minimum n, band cut-offs, top-N), each guarded by reconciled figures ([`dashboard/README.md`](../../dashboard/README.md) §5.6); no eligibility, deduplication or exclusion logic in DAX |
| No orchestration for a one-time dataset | Met | One-command script (`run_pipeline.py`), no scheduler |
| No containers before the local workflow is stable | Met | None used |
| No machine learning | Met | None used |
| Every tool has a clear role | Met | `pandas` and `SQLAlchemy` were unused and were removed from `requirements.txt` and the README tech stack (item OI-10, resolved 2026-10-18); every remaining dependency (`psycopg`) is imported by a script |

---

## 6. Definition of Success (Scope §10 / Implementation Plan §9)

| Criterion | Status | Evidence |
|---|---|---|
| Reproducible from the documented public source and setup instructions | **Met** | §1 clean rebuild; [`../../README.md`](../../README.md#reproduce-in-5-steps); [`../../data/README.md`](../../data/README.md) (access constraint: the pinned file is not redistributed in Git) |
| The PostgreSQL model represents procurement relationships clearly, without unnecessary denormalisation | **Met** | [Phase 4 model](../phase4_data_model/phase4_relational_model.md), [ERD](../../diagrams/erd/nocopo_erd.md), Gate B 107 / 107 |
| Material data-quality issues identified before they influence conclusions | **Met** | Decision log complete before schema (Gate A); issues found later (DQ-19, DQ-20, DQ-21) went through approved correction passes before the findings were signed off |
| Every major claim traces to a documented SQL transformation and supporting data | **Met** | 236 / 236 claim-trace rows; tagged figures in the README and portfolio documents checked as well ([trace check](../phase10_findings/claim_trace_check_results.md)) |
| Advanced SQL used because the analysis requires it | **Met** | Window functions for concentration, rank and cumulative shares; CTEs for metric populations; materialised snapshot for release modelling; generated columns for data-quality flags ([`../methodology.md`](../methodology.md)) |
| Dashboard communicates a small set of decision-relevant metrics | **Met** | Eight pages mapped to the seven questions; 177 / 177 figures reconciled and signed |
| Recommendations proportional to the evidence; observation separate from interpretation | **Met** | [Findings](../phase10_findings/findings.md) §2 and §11 (Observed / Reading / Implications / Recommendation); prohibited-wording check |
| Demonstrates technical capability and business judgement | **Met** | Findings, methodology and the validation evidence |

**Implementation Plan Phase 12 activities**

| Activity | Status |
|---|---|
| Re-run the full validation suite end to end on a clean load | Done (§1) |
| Re-verify dashboard-to-SQL reconciliation | Done (§2) |
| Walk through the seven business questions | Done (§3) |
| Review against the anti-pattern list and technology non-goals | Done (§4, §5) |
| Confirm the project's portfolio-stage positioning | **Intentionally omitted — owner decision** (`42bf3ad`): portfolio-stage framing is kept out of public documents |

---

## 7. Repository checks

| Check | Result |
|---|---|
| Relative links, images and heading anchors (`python/validation/09_check_links.py`) | 0 broken |
| Findings trace check (`07_check_findings_trace.py --live`) | pass |
| Attribution lines, agent configuration files, secrets and local paths in tracked files and commit messages | none found |
| Raw data | not committed; `NOCOPO dataset/` gitignored; `.pbix` gitignored |

---

## 8. Outstanding-items register

| ID | Item | Status | Owner | Next action |
|---|---|---|---|---|
| OI-01 | DQ-21: the 45 flagged awards are not confirmed against source documents | Open; flagged and shown as sensitivity | Analyst, with the publisher | Check the award notices (findings R1, R4); confirmed errors would go through a correction pass |
| OI-02 | Source item B: the FMC Taraba award ([`source_verification.md`](../phase10_findings/source_verification.md) §B) | Unresolved; neither DQ-21 test applies | Analyst | Confirm at source |
| OI-03 | Source item C: the HADEJIA-JAMAÄ»ARE RBDA above-ten-times awards that fail the dropped-decimal test | Unresolved | Analyst | Confirm at source |
| OI-04 | DQ-12 transaction value semantics | Deferred / unresolved; transaction values never summed | Publisher | Needs field documentation from the publisher |
| OI-05 | DQ-11 transaction dates absent | Closed as a limitation (L-18) | — | — |
| OI-06 | DQ-13 / DQ-15 canonical supplier mapping | Deferred; concentration reported as a lower bound | Future work | Would need an approved, auditable mapping |
| OI-07 | DQ-17 identifier scheme uniformity | Deferred; no record-level footprint | — | — |
| OI-08 | Phase 7 suite planner setting (`enable_nestloop = off`) | Accepted workaround (owner decision, Phase 11); results identical | Owner | Optional: an index-friendly restructuring of the Phase 7 recounts, with approval |
| OI-09 | `.pbit` opened on a second machine | **Passed** (2026-10-18) | Owner (Kene) | None. The template was opened under a separate Windows user account with no saved credentials; recorded in `dashboard/USAGE.md` |
| OI-10 | Unused dependencies: `pandas`, `SQLAlchemy` in `requirements.txt`; pandas named in the README tech stack | **Resolved** (2026-10-18) | Owner | Removed from `requirements.txt` and the README; `09_check_links.py` and `07_check_findings_trace.py` pass on an environment built from the slimmer file |
| OI-11 | DQ-21 not in `vw_dq_impact`, script 07 or the dashboard | By design (existing views unchanged) | — | Optional future extension |
| OI-12 | No shared date dimension (P-10) | Accepted limitation (L-06) | — | — |
| OI-13 | Optional CI (GitHub Actions) | Not implemented; optional in the architecture | Future work | Could run `run_pipeline.py` against a containerised PostgreSQL |
| OI-14 | `dashboard/screenshots/.gitkeep` in a non-empty folder | Cosmetic | Owner | Remove in a later dashboard commit |
| OI-15 | Release tag `v1.0` | **Approved and created** (2026-10-18) | Owner (Kene) | None; see [`signoff_note.md`](signoff_note.md) §5 |
| OI-16 | Portfolio-stage positioning (Implementation Plan Phase 12) | Closed: intentionally omitted (owner decision) | — | — |

---

*QA checklist version 1.0 — 2026-10-18. Nothing in the raw file, SQL, findings or dashboard was changed by this QA.*
