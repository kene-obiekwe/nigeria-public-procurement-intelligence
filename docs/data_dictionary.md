# Data Dictionary — Analytical Layer (`analytics.*`)
# Nigeria Public Procurement Intelligence

> **Status:** Final (Phase 11). Covers the 16 views in schema `analytics`, the only objects Power BI and the analysis
> scripts may read. Column names and types are taken from the database catalogue (`information_schema.columns`);
> each view also carries a `COMMENT` in the database.
> **Field-level source dictionary** (raw OCDS field → meaning → staging column):
> [`phase3_data_quality/phase3_data_dictionary.md`](phase3_data_quality/phase3_data_dictionary.md).
> **Eligibility rules in full:** [`phase7_analytics/phase7_analytical_views.md`](phase7_analytics/phase7_analytical_views.md) §2.
> **Population sizes:** query `analytics.vw_metric_population`; this dictionary deliberately carries no counts.

Types: `varchar` = character varying; `numeric` amounts are NGN with four decimals unless stated; dates are `date`.

---

## 1. Columns shared by many views

| Column | Type | Meaning | Source |
|---|---|---|---|
| `ocid` | varchar | Open Contracting ID: one procurement process. The process grain of every metric. | `releases[].ocid` |
| `award_id`, `contract_id` | varchar | Award / contract identifier from the process snapshot | `awards[].id`, `contracts[].id` |
| `*_release_id` | varchar | Release the section was taken from (latest release carrying it; integer order) | `releases[].id` |
| `buyer_id` | varchar | Procuring-entity ID (`NG-BPP-BPP-NOC-<code>`); the bare `NG-BPP-` is DQ-19 | `releases[].buyer.id` |
| `buyer_name` | varchar | Buyer name as published, whitespace-normalised; never used for matching | `releases[].buyer.name` |
| `buyer_id_flag` | varchar | `INCOMPLETE` for the bare `NG-BPP-` buyer (DQ-19), otherwise NULL. Entity-level measures exclude it. | `core.dim_buyer` |
| `procurement_method_details` | varchar | Procurement method as published (NULL = not stated); the only category-like field | `tender.procurementMethodDetails` |
| `award_value_amount` | numeric | Award value. Tender and contract values equal it in every record (C-08). | `awards[].value.amount` |

Every view excludes the portal test entity `NG-BPP-BPP-NOC-90` (DQ-20, `core.dim_buyer.test_entity_flag`).

---

## 2. Metric views

### `vw_budget_eligible` — M-P01 planned budget (grain: budget line)
Rule: latest release per `(ocid, budget projectID)` (C-06); amount ≥ 0; excludes EXTREME (DQ-06), ZERO_VALUE (DQ-16),
releases without parties (DQ-18) and the bare buyer (DQ-19).

| Column | Type | Meaning |
|---|---|---|
| `budget_project_id` | varchar | Budget line key within the OCID (`planning.budget.projectID`) |
| `release_id` | varchar | Release carrying the latest version of the line |
| `budget_amount`, `budget_currency` | numeric, varchar | Planned amount and currency (a plan, not spend) |
| `budget_description`, `budget_project` | text | Descriptive text as published |
| `multi_project_flag` | text | `MULTI_PROJECT` when the OCID carries more than one unrelated budget line (C-06) |

### `vw_competition_eligible` — M-C01, M-C02 (grain: OCID)
Rule: snapshot tender with non-null status; tenderer flag NORMAL or ELEVATED (ANOMALOUS > 1,000 excluded, DQ-05).
Rows are the sensitivity population; `in_primary_population` selects the primary one (DQ-04).

| Column | Type | Meaning |
|---|---|---|
| `tender_id`, `tender_status` | varchar | Tender ID and status (all non-null statuses kept; decision I-3) |
| `number_of_tenderers` | integer | Recorded tenderer count; never imputed (what it counts is not defined in the source) |
| `tenderer_count_flag` | varchar | `NORMAL` (1–100), `ELEVATED` (101–1,000) |
| `in_primary_population` | boolean | True for NORMAL rows: the M-C01 / M-C02 population |
| `is_single_bidder` | boolean | `number_of_tenderers = 1` |

### `vw_award_value_eligible` — M-V01 (grain: OCID, one award)
Rule: snapshot award with status `active`; excludes EXTREME (DQ-07) and ZERO_VALUE (DQ-16).

| Column | Type | Meaning |
|---|---|---|
| `award_value_currency` | varchar | Currency of the award |
| `award_date`, `award_date_flag` | date, varchar | Award date and its class: VALID / PLACEHOLDER (DQ-08) / FUTURE / IMPOSSIBLE (DQ-09) |

### `vw_supplier_award_eligible` — M-S01 (grain: award × distinct supplier)
Rule: the M-V01 rule, plus a usable supplier ID (bare `NG-BPP-` excluded, DQ-14); repeated `suppliers[]` entries
collapsed. Full award value is attributed to its single supplier (decision I-5).

| Column | Type | Meaning |
|---|---|---|
| `supplier_id`, `supplier_name` | varchar | Supplier as published; IDs are never merged (DQ-13, DQ-15) |
| `name_variant_count` | integer | Number of distinct names seen for this supplier ID (DQ-13 indicator) |
| `distinct_supplier_count` | bigint | Distinct suppliers on the award (always 1 in this population; check AV-07) |

### `vw_budget_award_comparison` — Pillar 4 / question 3 (grain: OCID)
Rule: an M-V01 award and exactly one budget line (multi-project OCIDs excluded, decision I-2) with budget > 0, not
EXTREME, not ZERO. Budget against award is the only valid financial comparison (C-08).

| Column | Type | Meaning |
|---|---|---|
| `budget_project_id`, `budget_amount` | varchar, numeric | The single budget line compared |
| `variance_amount` | numeric | Award minus budget (positive: award above budget). Not an overrun or a saving. |
| `award_to_budget_ratio` | numeric | Award / budget, four decimals; extreme ratios kept |

### `vw_tender_duration_eligible` — M-E01 (grain: OCID)
Rule: both tender-period dates VALID and end ≥ start.

| Column | Type | Meaning |
|---|---|---|
| `tender_start_date`, `tender_end_date` | date | `tender.tenderPeriod` dates |
| `tender_duration_days` | integer | End minus start, in days |

### `vw_award_lag_eligible` — M-E02 (grain: OCID)
Rule: VALID tender start and award dates, award ≥ tender start (chronology conflicts excluded, not corrected),
single-award OCID (C-03). Award status is carried, not filtered (I-4).

| Column | Type | Meaning |
|---|---|---|
| `award_status` | varchar | Award status as published |
| `tender_start_date`, `award_date` | date | The two event dates |
| `award_lag_days` | integer | Award date minus tender start |

### `vw_signature_lag_eligible` — P5-SIG (grain: contract)
Rule: VALID award and signature dates, signed ≥ award. Secondary timing measure (no Phase 3 metric ID; I-7).

| Column | Type | Meaning |
|---|---|---|
| `award_date`, `date_signed` | date | Award date and `contracts[].dateSigned` |
| `signature_lag_days` | integer | Signature date minus award date |

### `vw_lifecycle_stage` — M-E03 (grain: OCID)
Rule: none; every OCID (DQ-20 excluded) with the highest stage reported across all its releases.

| Column | Type | Meaning |
|---|---|---|
| `release_count` | bigint | Releases published for the OCID |
| `tags_observed` | text[] | Distinct lifecycle tags across those releases |
| `highest_stage_rank`, `highest_stage` | integer, text | 1 planning, 2 tender, 3 award, 4 contract, 5 implementation. What was published, not what occurred. |

### `vw_contract_implementation_coverage` — M-I01 (grain: contract)
Rule: none; one snapshot contract per OCID.

| Column | Type | Meaning |
|---|---|---|
| `contract_status` | varchar | Contract status as published |
| `has_implementation` | boolean | Implementation transactions or milestones were published. Reporting coverage, not performance. |
| `transaction_count`, `implementation_milestone_count` | bigint | Counts only; transaction values are never summed (DQ-12) and have no dates (DQ-11) |

### `vw_entity_benchmark` — procuring-entity KPIs (grain: buyer)
Rule: complete buyer IDs only (DQ-19 excluded). Each measure inherits its metric view's eligibility and sits beside
its own n. NULL means no eligible records, never zero.

| Column | Type | Meaning |
|---|---|---|
| `process_count`, `processes_reaching_tender`, `processes_reaching_award` | bigint | OCIDs and how many reach each stage (M-E03 basis) |
| `tender_reach_rate` | numeric | Share of the entity's OCIDs that reach tender (fraction) |
| `budget_line_n`, `planned_budget_total` | bigint, numeric | M-P01 lines and total |
| `competition_n`, `median_tenderers`, `single_bidder_rate` | bigint, double, numeric | M-C01 / M-C02 on the primary population (rate as a fraction) |
| `award_n`, `award_value_total`, `median_award_value` | bigint, numeric, numeric | M-V01 awards, total and median |
| `distinct_supplier_n`, `top_supplier_value_share` | bigint, numeric | M-S01 at entity level: suppliers and the largest one's share (fraction), on awards with a usable supplier ID |
| `contract_n`, `implementation_coverage_rate` | bigint, numeric | M-I01 contracts and coverage (fraction) |

---

## 3. Register, quality and flag views

### `vw_metric_population` — eligible population register (grain: metric)
`metric_id`, `metric_name`, `grain`, `candidate_population` (text); `candidate_count`, `eligible_count` (bigint);
`eligible_pct` (numeric). Show beside any reported metric.

### `vw_dq_impact` — question 7 (grain: metric × data-quality issue)
Reads `core` / `stg` by design, to see the excluded side; eligible counts come from the metric views.

| Column | Type | Meaning |
|---|---|---|
| `metric_order`, `metric_id`, `metric_name`, `grain` | integer, text | The metric |
| `dq_ref`, `dq_issue`, `treatment` | text | Issue (DQ-xx, C-06, DATE-ORDER, `SUMMARY_ALL`, `SUMMARY_OTHER`) and its treatment |
| `impact_type` | text | `EXCLUDES`, `EXCLUDES_FROM_PRIMARY`, `DISCLOSED` (kept, limits interpretation), `PRE_EXCLUDED` (DQ-20) |
| `candidate_records`, `eligible_records` | bigint | Metric populations |
| `records_with_issue` | bigint | Candidates tripping the issue (overlaps across issues) |
| `records_lost_only_to_issue` | bigint | Candidates removed by this issue alone (additive) |
| `pct_of_candidate` | numeric | `records_with_issue` as a percentage of candidates |
| `affected_value_ngn`, `eligible_value_ngn` | numeric | Value at stake and eligible value, NGN |
| `note` | text | How to read the row |

### `vw_award_scale_flag` — DQ-21 possible scale errors (grain: flagged award only)
FLAG for sensitivity result sets; no metric view reads it, and nothing is excluded. Candidates are M-V01 awards.

| Column | Type | Meaning |
|---|---|---|
| `supplier_id` | varchar | Supplier where usable (needed for the sibling-lot test) |
| `scale_flag` | varchar | Always `POSSIBLE_SCALE_ERROR` |
| `flag_reason` | varchar | `DROPPED_DECIMAL`, `SIBLING_LOT` or both |
| `dropped_decimal_test`, `sibling_lot_test` | boolean | Which test the award passes |
| `budget_project_id`, `budget_amount`, `award_to_budget_ratio` | varchar, numeric | Budget comparator (dropped-decimal test: whole-naira award at 50–200 times budget) |
| `sibling_award_id`, `sibling_award_value`, `ratio_to_sibling` | varchar, numeric | Largest other award of the same supplier from the same buyer (sibling-lot test: at least 500 times) |

---

## 4. Presentation dimensions (Power BI)

| View | Columns | Meaning |
|---|---|---|
| `vw_dim_buyer` | `buyer_id` (key), `buyer_name`, `buyer_code` (ID without the `NG-BPP-BPP-NOC-` prefix), `buyer_label` (name plus code, unique) | Complete buyer IDs only (DQ-19, DQ-20 excluded); the label separates names shared by two IDs |
| `vw_dim_procurement_method` | `procurement_method` (key), `is_not_stated` | Every method used by a fact view plus `(method not stated)` |

---

*Data dictionary version 1.0 — 2026-10-17.*
