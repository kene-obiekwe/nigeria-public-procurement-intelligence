# Phase 3 Draft Analytical Data Dictionary
# Nigeria Public Procurement Intelligence

> **Phase:** 3 — Data Dictionary Specification
> **Decision date:** 2026-08-16
> **Approved by:** Project owner
> **This document is SPECIFICATION ONLY. No relational tables have been designed yet.**
> **All source locations reference the raw OCDS JSON structure in `NOCOPO dataset/all07010.json`.**

---

## Purpose

This data dictionary documents the business meaning, data type, quality status,
and analytical role of every field that will be important in the eventual
relational model. It serves as the authoritative reference for:

- Phase 4 staging-layer column definitions.
- Phase 4 transformation logic.
- Phase 5 analytical view documentation.
- Power BI field descriptions and report annotations.

Fields are organised by the procurement object they belong to, not by
eventual table structure (that is a Phase 4 concern).

---

## Field Notation

| Symbol | Meaning |
|--------|---------|
| (PK) | Will become a primary key in the relational model |
| (FK) | Will become a foreign key referencing another entity |
| (DQ) | Has a documented data-quality issue; see DQ-XX reference |
| (DERIVED) | Does not exist in source; must be computed during transformation |
| (FLAG) | A data-quality flag column to be created in staging |

---

## Section 1: Release-Level Fields

### 1.1 release_id

| Attribute | Detail |
|-----------|--------|
| **Field name** | `release_id` |
| **Source location** | `releases[].id` |
| **Business meaning** | Unique identifier for this specific release event. One release represents one disclosure notification published by the procuring entity. A procurement process (OCID) may have multiple releases. |
| **Data type** | String |
| **Expected values / range** | Unique integer-like string across all 108,277 releases (confirmed: 108,277 unique release IDs) |
| **Missingness** | 0 null (0%) |
| **Quality issues** | None |
| **Analytical role** | (PK) Primary key of the release table in the relational model |
| **Transformation required** | None — use as-is |
| **Notes** | Do not confuse with OCID. Release IDs are globally unique; OCIDs are process-level identifiers repeated across releases. |

---

### 1.2 ocid

| Attribute | Detail |
|-----------|--------|
| **Field name** | `ocid` |
| **Source location** | `releases[].ocid` |
| **Business meaning** | Open Contracting Identifier. Uniquely identifies a procurement process. Multiple releases can share the same OCID, each representing a different lifecycle stage of the same process. |
| **Data type** | String |
| **Expected values / range** | Format: `ocds-gyl66f-{entity_code}-{sequence}`. 98,866 unique values across 108,277 releases. |
| **Missingness** | 0 null (0%) |
| **Quality issues** | DQ-01 (6,280 OCIDs appear in >1 release; 9,411 excess releases). Standard OCDS behaviour — not a data error. |
| **Analytical role** | (FK) Foreign key linking releases to the procurement process. Primary grouping key for process-level analysis. |
| **Transformation required** | None at field level. Analytical views must apply process-snapshot rule when aggregating across releases per OCID. |
| **Notes** | The entity code segment (e.g. 231001001) may encode the procuring entity or budget code. Not formally decoded. |

---

### 1.3 release_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `release_date` |
| **Source location** | `releases[].date` |
| **Business meaning** | The date and time this release was published to NOCOPO. For this dataset, all releases were published as part of a single bulk export. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | All 108,277 releases = `2021-05-03T22:44:00Z` |
| **Missingness** | 0 null (0%) |
| **Quality issues** | DQ-10 — represents the package publication date, not the procurement event date. Cannot be used for temporal analysis. |
| **Analytical role** | Metadata only. NOT used for procurement event timing. |
| **Transformation required** | Parse to datetime type. Store as metadata. Do NOT use for time-series analysis. |
| **Notes** | Internal event dates (tender start, award date, contract signed date) must be used instead. |

---

### 1.4 release_tag

| Attribute | Detail |
|-----------|--------|
| **Field name** | `release_tag` |
| **Source location** | `releases[].tag` (array of strings) |
| **Business meaning** | Identifies which procurement lifecycle stage(s) are present in this release. A release with tag [planning] contains only planning/budget data. A full lifecycle release carries [planning, tender, award, contract, implementation]. |
| **Data type** | Array of strings |
| **Expected values / range** | Values: planning, tender, award, contract, implementation |
| **Missingness** | Not observed null |
| **Quality issues** | DQ-02 — 89,869 releases (83%) have only [planning] tag |
| **Analytical role** | (DERIVED) Use to classify each OCID by its maximum observed lifecycle stage. Primary population filter for all analytical pillars. |
| **Transformation required** | In staging: derive `max_lifecycle_stage` column per OCID (PLANNING / TENDER / AWARD / CONTRACT / IMPLEMENTATION). |
| **Notes** | A release tagged [implementation] indicates implementation records were submitted; it does not confirm successful contract completion. |

---

## Section 2: Buyer / Procuring Entity Fields

### 2.1 buyer_id

| Attribute | Detail |
|-----------|--------|
| **Field name** | `buyer_id` |
| **Source location** | `releases[].buyer.id` |
| **Business meaning** | Unique identifier of the procuring entity responsible for this procurement process. Format: NG-BPP-BPP-NOC-{code}. |
| **Data type** | String |
| **Expected values / range** | 666 unique buyer IDs. Format: NG-BPP-BPP-NOC-NNNNNNNN |
| **Missingness** | 0 null (0%) in releases |
| **Quality issues** | DQ-18 — 20 releases have no parties array (buyer field may still be populated separately) |
| **Analytical role** | (FK) Primary entity identifier for buyer-level analysis |
| **Transformation required** | None — use as-is |
| **Notes** | The numeric code segment encodes the entity (e.g. 231001001 = Federal Ministry of Works and Housing). Formal mapping to a published entity register not yet performed. |

---

### 2.2 buyer_name

| Attribute | Detail |
|-----------|--------|
| **Field name** | `buyer_name` |
| **Source location** | `releases[].buyer.name` |
| **Business meaning** | Display name of the procuring entity. |
| **Data type** | String |
| **Expected values / range** | 680 unique names observed (slight discrepancy with 666 buyer IDs indicates minor name variation) |
| **Missingness** | Not observed null |
| **Quality issues** | Minor name variation |
| **Analytical role** | Display label only. Use `buyer_id` as the grouping key. |
| **Transformation required** | STANDARDIZE — whitespace trim; preserve original in `buyer_name_raw` |
| **Notes** | Use buyer_id for grouping to avoid miscounting from name variants. |

---

## Section 3: Planning / Budget Fields

### 3.1 budget_amount

| Attribute | Detail |
|-----------|--------|
| **Field name** | `budget_amount` |
| **Source location** | `releases[].planning.budget.amount.amount` |
| **Business meaning** | Planned budget allocation for this procurement process as reported to NOCOPO at the planning stage. |
| **Data type** | Numeric (float) |
| **Expected values / range** | 0 to 6,500,000,000,000 NGN. Median: ~NGN 55.3 million. P99: NGN 16.5 billion. 32 records >= NGN 1 trillion. |
| **Missingness** | ~1,649 null (~1.5%) |
| **Quality issues** | DQ-06 (32 extreme records >= NGN 1T); DQ-16 (561 zero-value records) |
| **Analytical role** | Primary monetary field for Pillar 1. Excluded when flagged EXTREME or ZERO_VALUE per metric. |
| **Transformation required** | Parse from planning.budget.amount object. Cast to NUMERIC(30,2). Derive `budget_amount_flag`. |
| **Notes** | This is planned spend, not actual expenditure. Do not treat as equivalent to award value. |

---

### 3.2 budget_currency

| Attribute | Detail |
|-----------|--------|
| **Field name** | `budget_currency` |
| **Source location** | `releases[].planning.budget.amount.currency` |
| **Business meaning** | Currency of the budget amount. |
| **Data type** | String (ISO 4217) |
| **Expected values / range** | All observed values: NGN |
| **Missingness** | Not observed null where budget_amount is present |
| **Quality issues** | None observed |
| **Analytical role** | Confirmation field. No FX conversion required. |
| **Transformation required** | None |
| **Notes** | Confirm uniformity in Phase 4 full scan. |

---

### 3.3 budget_description

| Attribute | Detail |
|-----------|--------|
| **Field name** | `budget_description` |
| **Source location** | `releases[].planning.budget.description` |
| **Business meaning** | Free-text description of the budget line or procurement purpose at planning stage. |
| **Data type** | String |
| **Expected values / range** | Free text |
| **Missingness** | Not profiled |
| **Quality issues** | None |
| **Analytical role** | Descriptive / search. Not used in quantitative metrics. |
| **Transformation required** | STANDARDIZE — whitespace trim |
| **Notes** | May contain useful classification signals for procurement category analysis. |

---

## Section 4: Tender Fields

### 4.1 tender_value_amount

| Attribute | Detail |
|-----------|--------|
| **Field name** | `tender_value_amount` |
| **Source location** | `releases[].tender.value.amount` |
| **Business meaning** | Estimated value of the tender at the time the tender was issued. |
| **Data type** | Numeric (float) |
| **Expected values / range** | 0 to NGN ~1.004 trillion. Median: ~NGN 27 million. |
| **Missingness** | Null in 81,869 releases with no tender section; within tender releases, profile in Phase 4 |
| **Quality issues** | DQ-16 (1,259 zeros); tender value often equals award value (possible field misuse) |
| **Analytical role** | Input for Pillar 4 (budget-to-award comparison). Secondary to award value. |
| **Transformation required** | Parse from tender.value object. Cast to NUMERIC(30,2). |
| **Notes** | In OCDS, tender value is an estimate; many records show it equals the award value exactly, suggesting possible retroactive population. Treat with caution in value comparisons. |

---

### 4.2 number_of_tenderers

| Attribute | Detail |
|-----------|--------|
| **Field name** | `number_of_tenderers` |
| **Source location** | `releases[].tender.numberOfTenderers` |
| **Business meaning** | Number of organisations that submitted a tender (bid) for this procurement process. |
| **Data type** | Integer |
| **Expected values / range** | 1 to 90,865. Median: 2. P95: 9. P99: 24. 65 records > 1,000 (all from Federal Ministry of Works and Housing). |
| **Missingness** | 0 null in 18,408 tender releases (0%) — confirmed |
| **Quality issues** | DQ-03 (normal: 1–100); DQ-04 (elevated: 101–1,000, 79 records); DQ-05 (anomalous: >1,000, 65 records from one entity) |
| **Analytical role** | Primary field for Pillar 2 competition analysis. |
| **Transformation required** | Derive (FLAG): `tenderer_count_flag` = NORMAL (1–100) / ELEVATED (101–1,000) / ANOMALOUS (>1,000). |
| **Notes** | All 65 anomalous records are from buyer NG-BPP-BPP-NOC-231001001 (Federal Ministry of Works and Housing). Exclusion from primary competition metrics is mandatory per DQ-05. |

---

### 4.3 procurement_method

| Attribute | Detail |
|-----------|--------|
| **Field name** | `procurement_method` |
| **Source location** | `releases[].tender.procurementMethod` |
| **Business meaning** | OCDS standard classification of procurement method. |
| **Data type** | String |
| **Expected values / range** | All observed values: `open` |
| **Missingness** | Not observed null in tender releases |
| **Quality issues** | Appears uniform — not useful for segmentation without `procurement_method_details` |
| **Analytical role** | Low priority. Use `procurement_method_details` for method segmentation. |
| **Transformation required** | None |
| **Notes** | Confirm uniformity in Phase 4 full scan. |

---

### 4.4 procurement_method_details

| Attribute | Detail |
|-----------|--------|
| **Field name** | `procurement_method_details` |
| **Source location** | `releases[].tender.procurementMethodDetails` |
| **Business meaning** | Granular classification of the procurement approach: National Competitive Bidding, Selective Tendering, Direct Procurement, etc. |
| **Data type** | String |
| **Expected values / range** | Observed: National Competitive Bidding, Selective Tendering, Direct Procurement. Full distribution not profiled. |
| **Missingness** | Present in tender releases only; null rate in tender releases not profiled |
| **Quality issues** | None observed |
| **Analytical role** | **Primary segmentation field** for method-based analysis across all five pillars. |
| **Transformation required** | STANDARDIZE — whitespace trim; check for case variants of same method name |
| **Notes** | This field is preferred over `procurement_method` for all analytical segmentation. |

---

### 4.5 tender_start_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `tender_start_date` |
| **Source location** | `releases[].tender.tenderPeriod.startDate` |
| **Business meaning** | Date the tender window opened for bid submissions. Primary event date for tender processes. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: 9,622. Valid: 9,593. Range: 2010-07-05 to 2025-10-24. |
| **Missingness** | 8,786 null (47.7% of 18,408 tender releases) |
| **Quality issues** | DQ-08 (24 placeholder 2001-01-01 dates); DQ-09 (5 future dates 2026–2029) |
| **Analytical role** | Primary event date for procurement timing analysis (Pillar 5). Used in metrics M-E01, M-E02. |
| **Transformation required** | Parse to DATE type. Derive `tender_start_date_flag` (VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE). |
| **Notes** | 47.7% null rate is the most significant data coverage gap for timing analysis. |

---

### 4.6 tender_end_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `tender_end_date` |
| **Source location** | `releases[].tender.tenderPeriod.endDate` |
| **Business meaning** | Date the tender window closed. Used with `tender_start_date` to compute tender open duration. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: 9,622. Valid: 9,616. Range: 2010-08-15 to 2025-12-29. |
| **Missingness** | 8,786 null (47.7%) |
| **Quality issues** | DQ-09 (6 future dates 2026–2029) |
| **Analytical role** | Used with `tender_start_date` for M-E01 (tender duration). |
| **Transformation required** | Parse to DATE type. Derive `tender_end_date_flag`. |
| **Notes** | Null rate matches `tender_start_date` exactly — where one is null, both are null. |

---

### 4.7 tender_status

| Attribute | Detail |
|-----------|--------|
| **Field name** | `tender_status` |
| **Source location** | `releases[].tender.status` |
| **Business meaning** | Current status of the tender (e.g. active, complete, cancelled). |
| **Data type** | String |
| **Expected values / range** | Expected OCDS values: active, complete, cancelled, unsuccessful, withdrawn. Full distribution not profiled. |
| **Missingness** | Not profiled |
| **Quality issues** | None expected |
| **Analytical role** | Filter field for competition analysis |
| **Transformation required** | None |
| **Notes** | Profile distribution in Phase 4. |

---

## Section 5: Award Fields

### 5.1 award_id

| Attribute | Detail |
|-----------|--------|
| **Field name** | `award_id` |
| **Source location** | `releases[].awards[].id` |
| **Business meaning** | Identifier for an award within a procurement process. Used to deduplicate awards across multiple releases for the same OCID. |
| **Data type** | String |
| **Expected values / range** | Not globally unique; unique within a procurement process |
| **Missingness** | Not profiled |
| **Quality issues** | None |
| **Analytical role** | (PK candidate for awards table). Must be combined with OCID for global uniqueness. Critical deduplication key. |
| **Transformation required** | Create composite key: `ocid + award_id` for global uniqueness. |
| **Notes** | Award ID deduplication is mandatory for preventing double-counting of award values across multi-release OCIDs. |

---

### 5.2 award_value_amount

| Attribute | Detail |
|-----------|--------|
| **Field name** | `award_value_amount` |
| **Source location** | `releases[].awards[].value.amount` |
| **Business meaning** | Monetary value of the contract awarded to the winning supplier(s). Primary financial metric for contracting analysis. |
| **Data type** | Numeric (float) |
| **Expected values / range** | 0 to NGN 1,004,166,666,735.23. Median: ~NGN 33.5 million. P99: NGN 1.49 billion. |
| **Missingness** | 0 null in 17,417 awards (0%) — confirmed |
| **Quality issues** | DQ-07 (1 extreme record: NGN 1.004T, FCTA warehouse); DQ-16 (268 zero-value records) |
| **Analytical role** | Primary field for Pillars 3 and 4. Excluded from primary distribution when EXTREME or ZERO_VALUE. |
| **Transformation required** | Parse from `awards[].value` object. Cast to NUMERIC(30,2). Derive `award_value_flag`. |
| **Notes** | The FCTA NGN 1.004T record is retained but excluded from distribution benchmarks. Report separately in high-value analysis. |

---

### 5.3 award_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `award_date` |
| **Source location** | `releases[].awards[].date` |
| **Business meaning** | Date on which the award decision was made and notified. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: 14,787. Valid: 14,658. Range of valid dates: 2001-05-22 to 2025-10-29. |
| **Missingness** | 2,630 null (15.1% of 17,417 awards) |
| **Quality issues** | DQ-08 (119 placeholder 2001-01-01 dates); DQ-09 (extreme future dates including year 2922 and year 2033) |
| **Analytical role** | Primary event date for award timing (Pillar 5, M-E02). |
| **Transformation required** | Parse to DATE type. Derive `award_date_flag` (VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE). |
| **Notes** | Year-2922 award date is confirmed as a data-entry error. Flagged IMPOSSIBLE. |

---

### 5.4 award_status

| Attribute | Detail |
|-----------|--------|
| **Field name** | `award_status` |
| **Source location** | `releases[].awards[].status` |
| **Business meaning** | Current status of the award. |
| **Data type** | String |
| **Expected values / range** | active: 16,845 (96.7%); cancelled: 386; pending: 159; unsuccessful: 25 |
| **Missingness** | Not profiled for null; full distribution confirmed |
| **Quality issues** | None |
| **Analytical role** | Filter field — use `award_status = 'active'` for primary value analysis |
| **Transformation required** | None |
| **Notes** | Cancelled and unsuccessful awards retained but excluded from value concentration metrics. |

---

## Section 6: Supplier Fields

### 6.1 supplier_id

| Attribute | Detail |
|-----------|--------|
| **Field name** | `supplier_id` |
| **Source location** | `releases[].awards[].suppliers[].id` and `releases[].parties[role=supplier].id` |
| **Business meaning** | Unique identifier of the supplier awarded the contract. Primary analytical identity for supplier-level analysis. |
| **Data type** | String |
| **Expected values / range** | Format: NG-BPP-BPP-CI-NNNN (complete) or NG-BPP- (incomplete). 10,296 unique non-null IDs. |
| **Missingness** | 0 null in observed supplier party records |
| **Quality issues** | DQ-13 (1,483 IDs map to multiple names); DQ-14 (571 names map to multiple IDs, including incomplete identifiers) |
| **Analytical role** | (PK candidate for supplier dimension). Primary grouping key for supplier analysis. |
| **Transformation required** | Derive `supplier_id_flag = 'INCOMPLETE'` where ID matches pattern `NG-BPP-$` or other incomplete formats. |
| **Notes** | Use `supplier_id`, not `supplier_name`, as the primary grouping key. |

---

### 6.2 supplier_name

| Attribute | Detail |
|-----------|--------|
| **Field name** | `supplier_name` |
| **Source location** | `releases[].awards[].suppliers[].name` and `releases[].parties[role=supplier].name` |
| **Business meaning** | Display name of the awarded supplier as recorded at the time of the award. |
| **Data type** | String |
| **Expected values / range** | 12,717 unique names observed |
| **Missingness** | Not profiled for null |
| **Quality issues** | DQ-13 (same entity appears under multiple name formats) |
| **Analytical role** | Display label only. Not used as grouping key. |
| **Transformation required** | STANDARDIZE — whitespace trim and case normalisation for display. Preserve `supplier_name_raw`. |
| **Notes** | Do not merge suppliers based on name similarity alone. |

---

## Section 7: Contract Fields

### 7.1 contract_id

| Attribute | Detail |
|-----------|--------|
| **Field name** | `contract_id` |
| **Source location** | `releases[].contracts[].id` |
| **Business meaning** | Identifier for the contract within a procurement process. |
| **Data type** | String |
| **Expected values / range** | Not globally unique — combined with OCID for uniqueness |
| **Missingness** | Not profiled |
| **Quality issues** | None |
| **Analytical role** | (PK candidate for contracts table). Critical deduplication key. |
| **Transformation required** | Create composite key: `ocid + contract_id`. |
| **Notes** | Same deduplication approach as `award_id`. |

---

### 7.2 contract_status

| Attribute | Detail |
|-----------|--------|
| **Field name** | `contract_status` |
| **Source location** | `releases[].contracts[].status` |
| **Business meaning** | Current status of the contract. |
| **Data type** | String |
| **Expected values / range** | active: 16,450; cancelled: 357; pending: 123; terminated: 113 |
| **Missingness** | Not profiled |
| **Quality issues** | None |
| **Analytical role** | Filter field for contract analysis |
| **Transformation required** | None |
| **Notes** | Terminated contracts (113) are a notable category for implementation analysis. |

---

### 7.3 contract_signed_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `contract_signed_date` |
| **Source location** | `releases[].contracts[].dateSigned` |
| **Business meaning** | Date the contract was formally signed. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: ~14,386. Valid: 14,305. Range: 2003-07-07 to 2025-12-18. |
| **Missingness** | 2,657 null (~15.6% of contract records) |
| **Quality issues** | DQ-08 (77 placeholder 2001-01-01 dates); DQ-09 (4 future dates 2026–2028) |
| **Analytical role** | Used for contract-signature lag (award to signed date). Pillar 5 efficiency analysis. |
| **Transformation required** | Parse to DATE type. Derive `contract_signed_date_flag`. |
| **Notes** | Date range extends to 2003, earlier than most other date fields (which start ~2010). May represent older contracts in the system. |

---

### 7.4 contract_period_start

| Attribute | Detail |
|-----------|--------|
| **Field name** | `contract_period_start` |
| **Source location** | `releases[].contracts[].period.startDate` |
| **Business meaning** | Date the contract performance period begins. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: ~7,174. Valid: 7,168. Range: 2002-05-13 to 2025-12-18. |
| **Missingness** | 9,872 null (~57.9% of contract records) |
| **Quality issues** | DQ-08 (3 placeholder dates) |
| **Analytical role** | Secondary contract timing field. High null rate limits use. |
| **Transformation required** | Parse to DATE type. Derive flag. |
| **Notes** | High null rate (57.9%) means this field cannot serve as a primary date in timing metrics. |

---

### 7.5 contract_period_end

| Attribute | Detail |
|-----------|--------|
| **Field name** | `contract_period_end` |
| **Source location** | `releases[].contracts[].period.endDate` |
| **Business meaning** | Scheduled end date of the contract performance period. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Non-null: ~7,171. Valid: 7,158. Range: 2010-09-30 to 2025-12-27. |
| **Missingness** | 9,872 null (~57.9%) |
| **Quality issues** | DQ-09 (13 future dates 2026–2027) |
| **Analytical role** | Used for contract duration analysis when paired with `contract_period_start`. |
| **Transformation required** | Parse to DATE type. Derive `contract_period_end_flag`. |
| **Notes** | The 13 future dates (2026–2027) may be legitimate multi-year contracts active at time of 2021 publication. Flagged FUTURE, not IMPOSSIBLE. |

---

## Section 8: Implementation Fields

### 8.1 implementation_transaction_value

| Attribute | Detail |
|-----------|--------|
| **Field name** | `implementation_transaction_value` |
| **Source location** | `releases[].contracts[].implementation.transactions[].value.amount` |
| **Business meaning** | Monetary value associated with a payment or disbursement transaction in the implementation phase. |
| **Data type** | Numeric (float) |
| **Expected values / range** | Present in all 13,617 transaction objects. Range not fully profiled. |
| **Missingness** | 0 null across 13,617 transactions — confirmed |
| **Quality issues** | DQ-12 — semantic meaning unclear (cumulative vs. incremental); do not sum without confirmation |
| **Analytical role** | DEFERRED — potential payment-value analysis subject to DQ-12 resolution |
| **Transformation required** | Parse from `transactions[].value` object. Cast to NUMERIC(30,2). Do NOT aggregate yet. |
| **Notes** | Whether values represent cumulative progress payments or instalments is not confirmed. Profile against award values in Phase 4 before including in any disbursement metric. |

---

### 8.2 implementation_transaction_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `implementation_transaction_date` |
| **Source location** | `releases[].contracts[].implementation.transactions[].date` |
| **Business meaning** | Would represent the date of a payment transaction if populated. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | **ABSENT** in all 13,617 transaction objects (0 occurrences) |
| **Missingness** | 100% absent — DQ-11 |
| **Quality issues** | DQ-11 — universally absent across all transaction objects |
| **Analytical role** | NOT AVAILABLE. Cannot be used for payment timing analysis. |
| **Transformation required** | N/A — field does not exist in source data |
| **Notes** | Most significant data gap for implementation analysis. Payment timing cannot be computed from this dataset. |

---

### 8.3 milestone_due_date

| Attribute | Detail |
|-----------|--------|
| **Field name** | `milestone_due_date` |
| **Source location** | `releases[].contracts[].implementation.milestones[].dueDate` |
| **Business meaning** | Scheduled completion date for an implementation milestone. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Present in 27,960 milestone objects. Quality not yet fully assessed. |
| **Missingness** | Not fully profiled |
| **Quality issues** | DQ-08 (placeholder 2001-01-01 dates observed in sampled milestones) |
| **Analytical role** | Potential implementation timing signal. Subject to quality assessment in Phase 4. |
| **Transformation required** | Parse to DATE type. Apply date quality classification. |
| **Notes** | May be the only available date signal for implementation timing. Quality assessment deferred to Phase 4. |

---

### 8.4 milestone_date_met

| Attribute | Detail |
|-----------|--------|
| **Field name** | `milestone_date_met` |
| **Source location** | `releases[].contracts[].implementation.milestones[].dateMet` |
| **Business meaning** | Actual date on which the milestone was completed. |
| **Data type** | ISO 8601 datetime string |
| **Expected values / range** | Not profiled |
| **Missingness** | Not profiled |
| **Quality issues** | Likely contains placeholder dates similar to `dueDate` |
| **Analytical role** | Potential implementation timing signal (paired with `dueDate` for milestone delay analysis). Subject to Phase 4 quality assessment. |
| **Transformation required** | Parse to DATE type. Apply date quality classification. |
| **Notes** | Not used in current metric framework until quality is confirmed. |

---

### 8.5 milestone_status

| Attribute | Detail |
|-----------|--------|
| **Field name** | `milestone_status` |
| **Source location** | `releases[].contracts[].implementation.milestones[].status` |
| **Business meaning** | Whether the milestone has been met. |
| **Data type** | String |
| **Expected values / range** | Observed: `met`. Full distribution not profiled. |
| **Missingness** | Not profiled |
| **Quality issues** | None observed |
| **Analytical role** | Filter/classification for milestone analysis |
| **Transformation required** | None |
| **Notes** | Profile full distribution in Phase 4. |

---

## Section 9: Summary — Field Priority for Phase 4 Staging

| Priority | Field | Reason |
|----------|-------|--------|
| **Critical** | `ocid`, `release_id`, `buyer_id`, `buyer_name` | Core process and entity identity |
| **Critical** | `budget_amount`, `award_value_amount` | Primary financial fields |
| **Critical** | `number_of_tenderers` | Primary competition metric field |
| **Critical** | `supplier_id`, `award_id` | Supplier concentration and deduplication keys |
| **Critical** | `release_tag` | Lifecycle stage classification |
| **High** | `award_date`, `tender_start_date`, `tender_end_date`, `contract_signed_date` | Timing analysis |
| **High** | `procurement_method_details` | Method segmentation |
| **High** | `award_status`, `contract_status`, `tender_status` | Record validity filters |
| **Medium** | `tender_value_amount`, `budget_description`, `budget_currency` | Supporting financial fields |
| **Medium** | `contract_period_start`, `contract_period_end` | Contract duration (high null rate) |
| **Medium** | `implementation_transaction_value` | Payment analysis (semantic meaning deferred) |
| **Low** | `milestone_due_date`, `milestone_date_met`, `milestone_status` | Implementation timing (quality deferred) |
| **Metadata** | `release_date`, `initiation_type`, `procurement_method` | Context and confirmation only |

---

*Document version: 1.0 — 2026-08-16. Approved by project owner.*
*No relational tables have been designed. No SQL has been written.*
*Next reference: Phase 4 — Staging schema design and data loading.*
