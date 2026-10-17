# Business Requirements
# Nigeria Public Procurement Intelligence

> **Status:** Final (Phase 11). Consolidates the approved scope; it adds no new requirement.
> **Source documents:** [`00_project_planning/NOCOPO_SQL_Project_Scope.docx`](00_project_planning/NOCOPO_SQL_Project_Scope.docx)
> (problem, questions, pillars, success criteria) and [`phase3_data_quality/phase3_metric_eligibility.md`](phase3_data_quality/phase3_metric_eligibility.md)
> (metric definitions). Results: [`phase10_findings/findings.md`](phase10_findings/findings.md).

---

## 1. Business problem

Public procurement produces published records at every stage: planning, tender, award, contract and
implementation. The Nigeria Open Contracting Portal (NOCOPO) publishes them in the Open Contracting Data Standard
(OCDS), but the raw export is a single large nested JSON file that is hard to use for decisions.

The project asks: **how can publicly available contracting data be turned into an analytical framework that helps
procurement stakeholders identify material patterns, compare procurement activity and decide where further review is
warranted, and how far can the data be trusted to show them?**

It is an advisory analytics case study, not an official analysis or an audit. It does not set out to establish
misconduct or causation; findings are observations, anomalies and areas for further review.

---

## 2. Stakeholders

| Stakeholder | Information need | Project output |
|---|---|---|
| Procurement management | Overall patterns; supplier and competition exposure | Executive KPIs, findings §1, dashboard page 1 |
| Procuring entities | How their activity compares with peers | Entity benchmark (`analytics.vw_entity_benchmark`, dashboard page 5) |
| Procurement analysts | Supplier, tender, award and contract detail | Analytical views and SQL outputs (`sql/06_analysis/`) |
| Risk / advisory | Unusual patterns and data-quality concerns | Exception indicators, `analytics.vw_dq_impact`, `analytics.vw_award_scale_flag` |

---

## 3. Business questions

| # | Question | Analysis script | Findings |
|---|---|---|---|
| 1 | How concentrated is awarded value among suppliers, and how does it vary by entity or procurement category? | `sql/06_analysis/01_supplier_concentration.sql` | §3 |
| 2 | How competitive are processes, judged from recorded tenderer participation, and where is competition unusually low or high? | `02_competition.sql` | §4 |
| 3 | How does awarded value compare with planned budgets, and where is the variance notable? | `03_budget_to_award.sql` | §5 |
| 4 | What do valid tender, award and contract dates show about cycle duration, and where is date completeness insufficient? | `04_procurement_cycle_timing.sql` | §6 |
| 5 | Which procuring entities account for the most activity, and how do they compare across KPIs? | `05_entity_benchmarking.sql` | §7 |
| 6 | What share of contracts carries usable implementation or payment information? | `06_implementation_coverage.sql` | §8 |
| 7 | Which data-quality issues could materially change how the metrics should be read? | `07_data_quality_impact.sql` | §9 |

The questions are unchanged from the scope document (§6).

---

## 4. Analytical pillars

| Pillar | Purpose | Questions |
|---|---|---|
| Supplier concentration and competition | Supplier share, concentration and tenderer participation, accounting for supplier-ID quality | 1, 2 |
| Budget-to-award variance | Compare planned budgets with award values where the records are comparable | 3 |
| Procuring-entity benchmarking | Compare entities on transparent KPIs, each with its own population | 5 |
| Procurement-cycle efficiency | Timing from valid tender and award dates (secondary: date completeness requires filtering) | 4 |
| Implementation and reporting coverage | Availability of implementation information, never read as contractor performance | 6 |

Data-quality impact (question 7) runs across all pillars.

---

## 5. KPIs and metrics

Every metric has its own eligible population; the live register is `analytics.vw_metric_population` and must be shown
beside any reported value. Definitions: [`phase3_metric_eligibility.md`](phase3_data_quality/phase3_metric_eligibility.md);
implementation: [`data_dictionary.md`](data_dictionary.md).

| Metric ID | KPI | Grain | Analytical view |
|---|---|---|---|
| M-P01 | Total planned budget by entity | budget line (correction C-06) | `vw_budget_eligible` |
| M-C01 | Median number of tenderers (primary and sensitivity populations) | OCID | `vw_competition_eligible` |
| M-C02 | Single-bidder rate | OCID | `vw_competition_eligible` |
| M-V01 | Median award value | OCID (one award) | `vw_award_value_eligible` |
| M-S01 | Top-supplier award value concentration (top-N shares, Herfindahl index) | award × supplier | `vw_supplier_award_eligible` |
| P4-BvA | Budget-to-award ratio and variance | OCID | `vw_budget_award_comparison` |
| M-E01 | Median tender duration (days) | OCID | `vw_tender_duration_eligible` |
| M-E02 | Median award lag (days, tender start to award) | OCID | `vw_award_lag_eligible` |
| P5-SIG | Contract signature lag (days, award to signing; secondary measure) | contract | `vw_signature_lag_eligible` |
| M-E03 | Lifecycle conversion | OCID | `vw_lifecycle_stage` |
| M-I01 | Implementation reporting coverage | contract | `vw_contract_implementation_coverage` |
| ENTITY | Procuring-entity KPI profile | buyer | `vw_entity_benchmark` |

Supporting views: `vw_dq_impact` (question 7), `vw_award_scale_flag` (DQ-21 sensitivity), `vw_dim_buyer` and
`vw_dim_procurement_method` (dashboard dimensions).

---

## 6. Scope

**In scope:** ingestion and source documentation; profiling and data-quality assessment; lifecycle and release
modelling; PostgreSQL staging, core and analytical layers; validation suites; SQL analysis of the seven questions;
a Power BI dashboard over validated views only; executive findings and recommendations; reproducible GitHub
packaging.

**Out of scope:** a production procurement system; real-time monitoring; integration with government systems;
predicting or proving corruption, fraud, collusion or illegal activity; causal claims; replacing official audits;
machine learning; cloud deployment; confidential or non-public data.

---

## 7. Definition of success

From the scope document (§10), with where each is evidenced:

| Criterion | Evidence |
|---|---|
| Reproducible from the public source and setup instructions | `python/run_pipeline.py`; [`methodology.md`](methodology.md) §6 |
| The model represents procurement relationships clearly | [`phase4_data_model/phase4_relational_model.md`](phase4_data_model/phase4_relational_model.md), [ERD](../diagrams/erd/nocopo_erd.md) |
| Data-quality issues identified before they influence conclusions | [`phase3_data_quality/phase3_data_quality_decision_log.md`](phase3_data_quality/phase3_data_quality_decision_log.md) (DQ-01 to DQ-21) |
| Each major claim traces to SQL | [`phase10_findings/claim_trace.md`](phase10_findings/claim_trace.md) and its automated check |
| Advanced SQL used where the problem requires it | `sql/05_views/`, `sql/06_analysis/` (CTEs, window functions, materialised snapshot) |
| A focused, decision-relevant dashboard | [`../dashboard/README.md`](../dashboard/README.md), signed reconciliation log |
| Recommendations proportional to evidence, observation separate from interpretation | [`phase10_findings/findings.md`](phase10_findings/findings.md) §2, §11 |

The final check against these criteria is Phase 12.

---

*Business requirements version 1.0 — 2026-10-17.*
