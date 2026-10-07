# Nigeria Public Procurement Intelligence

**Turning Nigeria's open contracting data into an audited PostgreSQL analytics
database: one where every number can be traced to a validated SQL rule.**

> **Status: in progress.** Data audit and relational design are complete.
> Database implementation (staging → core → analytical views) is next.
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
├── docs/                     Planning documents, audit reports, decision logs, design
├── python/
│   ├── profiling/            Phase 2 profiling and targeted validation scripts
│   ├── validation/           Design-validation scripts (e.g. snapshot rule)
│   ├── ingest/               Staging loaders (Phase 5)
│   └── utils/
├── sql/
│   ├── 01_staging/           Staging DDL and load checks (Phase 5)
│   ├── 02_schema/            Core schema DDL (draft v1.1)
│   ├── 03_data_quality/      Validation suite (Phase 6)
│   ├── 04_transformations/   Controlled transformations (Phase 6)
│   ├── 05_views/             Analytical views per pillar (Phase 7)
│   └── 06_analysis/          Business-question queries (Phase 8)
├── diagrams/erd/             Entity-relationship diagram (Mermaid)
├── database/seed_and_setup/  Database setup scripts
└── dashboard/                Power BI dashboard and screenshots (Phase 9)
```

---

## Key documents

| Document | Purpose |
|---|---|
| [`docs/data_profiling_report.md`](docs/data_profiling_report.md) | Structural and data-quality profile of the raw file |
| [`docs/targeted_validation_report.md`](docs/targeted_validation_report.md) | Follow-up checks on profiling anomalies |
| [`docs/phase3_data_quality_decision_log.md`](docs/phase3_data_quality_decision_log.md) | Issues DQ-01 to DQ-18 with treatment decisions |
| [`docs/phase3_metric_eligibility.md`](docs/phase3_metric_eligibility.md) | Analytical grain and per-metric eligibility rules |
| [`docs/phase3_data_dictionary.md`](docs/phase3_data_dictionary.md) | Source field → meaning → target column |
| [`docs/phase4_relational_model.md`](docs/phase4_relational_model.md) | Relational design, release strategy, flag placement (v1.1) |
| [`docs/phase4_1_snapshot_validation_report.md`](docs/phase4_1_snapshot_validation_report.md) | Evidence behind the v1.1 snapshot rule |
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

Database build steps will be added as Phases 5–7 are implemented.

---

## Project status

| Phase | Scope | Status |
|---|---|---|
| 0–1 | Environment, repository, source inventory | Complete |
| 2 | Data profiling and audit | Complete |
| 3 | Data-quality decision log, metric eligibility, data dictionary | Complete (frozen) |
| 4 | Relational model, ERD, draft DDL | v1.1 in review |
| 5 | PostgreSQL staging load and reconciliation | Next |
| 6 | Core model and validation suite | Planned |
| 7–8 | Analytical views and business-question SQL | Planned |
| 9–10 | Power BI dashboard and executive findings | Planned |
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
