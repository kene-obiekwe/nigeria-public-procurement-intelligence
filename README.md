# Nigeria Public Procurement Intelligence

**Turning Nigeria's open contracting data into an audited PostgreSQL analytics
database: one where every number can be traced to a validated SQL rule.**

> **Status: in progress.** Data audit, relational design, the PostgreSQL
> staging load, the validated core model and the analytical layer are complete.
> **Gate B passed** (102/102); **Phase 7 views validated** (24/24); **Phase 8
> business-question SQL validated** (27/27). The Power BI dashboard (Phase 9) is next.
> See [Project status](#project-status).

---

## The business problem

Public procurement produces a large amount of published information at every
stage: planning, tender, award, contract and implementation. The **Nigeria Open
Contracting Portal (NOCOPO)** publishes this data. In raw form it is a 210 MB
nested JSON file, and it is hard to use for decisions.

This project takes the perspective of an advisory analytics team supporting
procurement and management stakeholders. It asks one question: **what patterns
in published procurement activity deserve management attention, and how far can
the data be trusted to show them?**

### Core business questions

1. How concentrated is awarded value among suppliers, by entity and category?
2. How competitive are procurement processes, judged from recorded tenderer participation?
3. How does awarded value compare with planned budgets?
4. What do valid tender, award and contract dates reveal about procurement-cycle duration?
5. Which procuring entities account for the most activity, and how do they compare?
6. What share of contracts carries usable implementation and payment information?
7. Which data-quality issues could materially change how these metrics should be read?

Findings are framed as observed patterns and areas for further review. The
project does **not** make claims of misconduct or causation.

---

## Approach

```
NOCOPO OCDS JSON (public, immutable)
        │  Python: structural profiling, targeted validation, loading
        ▼
PostgreSQL  stg.*        source-faithful staging, one row per release, DQ flags at grain
        ▼
PostgreSQL  core.*       validated entities: buyers, suppliers
        ▼
PostgreSQL  analytics.*  metric-specific eligibility views (snapshot rule, exclusions)
        ▼
Power BI                 presentation over validated views only
        ▼
Executive findings & recommendations
```

**Design principles**

- **Audit before schema.** No table was designed until profiling and the
  data-quality decision log were complete.
- **SQL-first.** Business logic and metrics live in PostgreSQL. Python handles
  ingestion and profiling. Power BI only presents.
- **No destructive cleaning.** Questionable records are retained and flagged,
  and are excluded only from the metrics they would distort. Missing values are
  never imputed as zero.
- **Eligibility is per metric.** There is no single "clean dataset". Every
  metric declares its own eligible population and reports its size.

---

## What the audit found

All figures below are measured. Each is documented in `docs/`.

| Finding | Evidence | Treatment |
|---|---|---|
| 108,277 releases describe only **98,866** procurement processes (OCIDs) | 6,280 OCIDs repeat across releases | A section-level snapshot rule prevents double-counting |
| Repeated releases are **not always identical** | 422 OCIDs revise their budget across releases; 192 hold unrelated budget lines | Integer-ordered "latest release" per section; budget handled at the budget-line grain |
| Release IDs sort incorrectly as text | Text ordering picks the wrong "latest" release in 1,508 OCIDs | Integer `release_seq` ordering key |
| Only ~17% of releases reach the tender stage | 89,869 releases are planning-only | Later-stage metrics report their own coverage |
| Implausible tenderer counts (max 90,865) | 65 records > 1,000 tenderers | Flagged `ANOMALOUS`, excluded from competition metrics |
| Placeholder and impossible dates (`2001-01-01`, year 2922) | Hundreds of date fields | Classified per date column; invalid dates excluded from timing metrics |
| Supplier identity is fragmented | 1,483 IDs map to multiple names; 571 names map to multiple IDs | Source IDs only; no name-similarity merging |
| Every release shares one publication date | 2021-05-03 on all 108,277 releases | Never used for temporal analysis |

---

## Repository structure

```
├── data/README.md            Source inventory, checksum, licence, acquisition notes
├── docs/                     Documentation grouped by phase (see docs/README.md)
│   ├── 00_project_planning/  Scope, architecture, data-quality plan, implementation plan
│   ├── phase2_profiling/     Profiling and targeted validation reports
│   ├── phase3_data_quality/  DQ decision log, metric eligibility, data dictionary, corrections
│   ├── phase4_data_model/    Relational model and snapshot-rule evidence
│   ├── phase5_staging/       Staging load and reconciliation
│   ├── phase6_core_model/    Core build, Gate B validation results
│   ├── phase7_analytics/     Analytical views, eligible populations, validation
│   └── phase8_analysis/      Business-question analysis, results and validation
├── python/
│   ├── profiling/            Phase 2 profiling and targeted validation scripts
│   ├── validation/           Design-validation scripts (e.g. snapshot rule)
│   ├── ingest/               Staging loader and reconciliation (Phase 5)
│   └── utils/
├── sql/
│   ├── 01_staging/           Staging DDL and load checks (Phase 5)
│   ├── 02_schema/            Staging + core schema DDL (v1.2, executed)
│   ├── 03_data_quality/      Validation suites: Gate B (01–08), views (09), analysis (10)
│   ├── 04_transformations/   Core dimensions + process snapshot (Phase 6)
│   ├── 05_views/             Metric-eligibility views (Phase 7) and DQ-impact view (Phase 8)
│   └── 06_analysis/          One script per business question (Phase 8)
├── diagrams/erd/             Entity-relationship diagram (Mermaid)
├── database/seed_and_setup/  Database setup scripts
└── dashboard/                Power BI dashboard and screenshots (Phase 9)
```

---

## Key documents

| Document | Purpose |
|---|---|
| [`docs/phase2_profiling/data_profiling_report.md`](docs/phase2_profiling/data_profiling_report.md) | Structural and data-quality profile of the raw file |
| [`docs/phase2_profiling/targeted_validation_report.md`](docs/phase2_profiling/targeted_validation_report.md) | Follow-up checks on profiling anomalies |
| [`docs/phase3_data_quality/phase3_data_quality_decision_log.md`](docs/phase3_data_quality/phase3_data_quality_decision_log.md) | Issues DQ-01 to DQ-18 with treatment decisions |
| [`docs/phase3_data_quality/phase3_metric_eligibility.md`](docs/phase3_data_quality/phase3_metric_eligibility.md) | Analytical grain and per-metric eligibility rules |
| [`docs/phase3_data_quality/phase3_data_dictionary.md`](docs/phase3_data_quality/phase3_data_dictionary.md) | Source field → meaning → target column |
| [`docs/phase3_data_quality/phase3_2_correction_log.md`](docs/phase3_data_quality/phase3_2_correction_log.md) | C-06: budget metric aggregated per budget line |
| [`docs/phase4_data_model/phase4_relational_model.md`](docs/phase4_data_model/phase4_relational_model.md) | Relational design, release strategy, flag placement (v1.1) |
| [`docs/phase4_data_model/phase4_1_snapshot_validation_report.md`](docs/phase4_data_model/phase4_1_snapshot_validation_report.md) | Evidence behind the v1.1 snapshot rule |
| [`docs/phase5_staging/phase5_staging_reconciliation.md`](docs/phase5_staging/phase5_staging_reconciliation.md) | Staging load, schema v1.2 changes, reconciliation and findings |
| [`docs/phase6_core_model/phase6_core_model.md`](docs/phase6_core_model/phase6_core_model.md) | Core build, design decisions, Gate B summary |
| [`docs/phase6_core_model/phase6_validation_results.md`](docs/phase6_core_model/phase6_validation_results.md) | Check-by-check Gate B results (119 checks) |
| [`docs/phase7_analytics/phase7_analytical_views.md`](docs/phase7_analytics/phase7_analytical_views.md) | Analytical views, eligibility rules, populations and disclosures |
| [`docs/phase8_analysis/phase8_business_question_analysis.md`](docs/phase8_analysis/phase8_business_question_analysis.md) | Script catalogue, findings by question, limitations, decisions |
| [`docs/phase8_analysis/phase8_analysis_results.md`](docs/phase8_analysis/phase8_analysis_results.md) | Every result set produced by the seven analysis scripts |
| [`diagrams/erd/nocopo_erd.md`](diagrams/erd/nocopo_erd.md) | Entity-relationship diagram |
| [`sql/02_schema/00_draft_core_schema.sql`](sql/02_schema/00_draft_core_schema.sql) | Draft DDL with constraints tied to DQ issues |

---

## Reproducing the work

**Prerequisites:** Python 3.12, PostgreSQL 15+, and the NOCOPO source file
described in [`data/README.md`](data/README.md), placed at
`NOCOPO dataset/all07010.json` and verified against its SHA-256.

```bash
python -m venv .venv
```

```bash
.venv/Scripts/python -m pip install -r requirements.txt
```

On macOS or Linux, use `.venv/bin/python` instead.

Run the scripts from the repository root. Each one reads the raw file
read-only and writes a Markdown report to `docs/`:

```bash
.venv/Scripts/python python/profiling/01_structural_profiler.py
```

```bash
.venv/Scripts/python python/profiling/02_targeted_validation.py
```

```bash
.venv/Scripts/python python/validation/03_snapshot_rule_validation.py
```

**Build the staging database** (PostgreSQL 15+; password via `pgpass.conf`;
connection defaults `localhost:5433`, user `postgres`, overridable with the
standard `PGHOST` / `PGPORT` / `PGUSER` / `PGDATABASE` variables):

```bash
psql -h localhost -p 5433 -U postgres -c "CREATE DATABASE nocopo_db WITH TEMPLATE template0 ENCODING 'UTF8'"
```

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/02_schema/00_draft_core_schema.sql
```

```bash
.venv/Scripts/python python/ingest/01_load_staging.py
```

```bash
.venv/Scripts/python python/ingest/02_reconcile_staging.py
```

**Build the core model and run the Gate B validation suite:**

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/04_transformations/01_build_dim_buyer.sql -f sql/04_transformations/02_build_dim_supplier.sql -f sql/04_transformations/03_process_snapshot.sql
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py
```

**Build the analytical views and validate them:**

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/01_budget_eligible.sql -f sql/05_views/02_competition_eligible.sql -f sql/05_views/03_award_and_supplier_eligible.sql -f sql/05_views/04_budget_award_comparison.sql -f sql/05_views/05_timing_eligible.sql -f sql/05_views/06_lifecycle_and_implementation.sql -f sql/05_views/07_entity_benchmark.sql -f sql/05_views/08_metric_population.sql
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 7
```

**Build the data-quality impact view, run the seven business-question scripts and validate them:**

```bash
psql -h localhost -p 5433 -U postgres -d nocopo_db -v ON_ERROR_STOP=1 -f sql/05_views/09_dq_impact.sql
```

```bash
.venv/Scripts/python python/validation/05_run_analysis_scripts.py
```

```bash
.venv/Scripts/python python/validation/04_run_validation_suite.py --phase 8
```

---

## Project status

| Phase | Scope | Status |
|---|---|---|
| 0–1 | Environment, repository, source inventory | Complete |
| 2 | Data profiling and audit | Complete |
| 3 | Data-quality decision log, metric eligibility, data dictionary | Complete (frozen) |
| 4 | Relational model, ERD, draft DDL | Complete (v1.1 approved) |
| 5 | PostgreSQL staging load and reconciliation | Complete (64/64 checks) |
| 6 | Core model and validation suite | Complete (Gate B: 102/102) |
| 7 | Analytical views (metric eligibility) | Complete (24/24 checks) |
| 8 | Business-question SQL | Complete (27/27 checks) |
| 9–10 | Power BI dashboard and executive findings | Next |
| 11–12 | Packaging and final QA | Planned |

---

## Tech stack

PostgreSQL · Python (standard library, pandas, psycopg, SQLAlchemy) · Power BI ·
Mermaid / diagrams.net · Git

---

## Licence and data

Code and documentation: MIT (see [`LICENSE`](LICENSE)).
Source data: Bureau of Public Procurement, published under ODC-PDDL (see [`NOTICE.md`](NOTICE.md)).
This is an independent portfolio analysis and is not endorsed by the BPP.
