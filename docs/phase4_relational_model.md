# Phase 4: Relational Data Model Design
# Nigeria Public Procurement Intelligence

> **Phase:** 4 — Relational Model + ERD + Draft DDL
> **Date:** 2026-08-20
> **Status:** DESIGN ARTIFACT — No DDL executed, no data loaded
> **Preceding phases:** Phase 2 (profiling), Phase 3 (DQ decisions), Phase 3.1 (corrections)

---

## 1. Phase 4 Objective

Design a defensible PostgreSQL relational model that transforms the complex OCDS
source structure into a relational analytical foundation while preserving:
source traceability, release history, OCID/process identity, all procurement
lifecycle stages, supplier identity, data-quality flags, analytical metric
eligibility, and future extensibility.

This document is the authoritative design reference for Phase 5 implementation.

---

## 2. Design Principles

1. **Evidence-driven:** Every table, key, and relationship is justified by
   empirical dataset inspection (108,277 releases, 98,866 OCIDs), not by
   theoretical OCDS schema documentation alone.

2. **Release-centric staging:** The staging layer preserves the source's
   release-centric structure. Each release is one row; nested objects
   (tender, awards, contracts) are extracted into child tables linked by
   release_id or their own globally-unique IDs.

3. **Non-destructive:** All 108,277 releases are retained. No releases are
   deleted. The analytical snapshot rule is implemented as a VIEW, not as
   physical deduplication.

4. **Flag-at-grain:** Data-quality flags are placed at the grain where the
   quality issue occurs (e.g., `award_value_flag` on the awards table,
   `tenderer_count_flag` on the tender table).

5. **Date flags per column:** Each date field gets its own quality flag column
   because different dates on the same record can have different quality
   statuses.

6. **SQL-first:** The relational model is designed for PostgreSQL analytical
   queries (CTEs, window functions, aggregations) without requiring
   Python or Power BI for core transformations.

7. **Three-layer architecture:** `stg.*` (staging) → `core.*` (dimensions) →
   `analytics.*` (views). This follows the approved 7-layer technology
   architecture (Layers 3→4→5).

---

## 3. Schema-Design Gate Answers

### 3.1 What constitutes a procurement process?

A procurement process is identified by its **OCID** (`releases[].ocid`).
One OCID = one procurement process. The dataset contains **98,866 unique OCIDs**
across 108,277 releases.

### 3.2 How do releases relate to that procurement process?

Each release is a published snapshot of a procurement process at a point in time.
One OCID may have 1 to 74 releases. 92,586 OCIDs have exactly 1 release; 6,280
OCIDs have 2+ releases (9,411 excess releases total).

Multi-release OCIDs carry identical data content with **different release-local
IDs** for nested objects. Both releases for a given OCID typically carry the same
lifecycle tags.

**Critical finding:** Award IDs and contract IDs are NOT reused across releases
for the same OCID. In 554 multi-release OCIDs with awards in both releases, each
release carries a different award ID for the same logical award (same value, same
supplier). Zero OCIDs have the same award ID appearing in more than one release.

### 3.3 Which source identifiers are sufficiently reliable to serve as keys?

| Identifier | Uniqueness | Nullable | Reliable? | Usage |
|-----------|-----------|----------|-----------|-------|
| `release_id` | 108,277 / 108,277 ✓ | 0% | **Yes** | PK for releases |
| `ocid` | 98,866 unique | 0% | **Yes** | Process grouping key |
| `buyer_id` | 666 unique | 0% | **Yes** | PK for buyer dimension |
| `award_id` | 17,417 / 17,417 ✓ | ~0% | **Yes** | PK for awards |
| `contract_id` | 17,043 / 17,043 ✓ | ~0% | **Yes** | PK for contracts |
| `supplier_id` | 10,296 unique | 0% | **Yes** | PK for supplier dimension |
| `tender_id` | 18,408 observed | Not profiled | Likely | Verify in Phase 5 |
| `transaction_id` | Not profiled | Unknown | Unclear | Surrogate PK |
| `milestone_id` | Not profiled | Unknown | Unclear | Surrogate PK |

### 3.4 Which relationships are actually populated?

| Relationship | Max cardinality | Evidence |
|-------------|----------------|---------|
| OCID → releases | 1:74 | 6,280 OCIDs with >1 release |
| Release → tender | 0:1 | Single object, 18,408 releases |
| Release → awards | 0:1 | Max 1 per release (17,417 total) |
| Release → contracts | 0:1 | Max 1 per release (17,043 total) |
| Release → parties | 0:2 | Max 2 per release (108,257 with parties) |
| Award → suppliers | 1:5 | 17,411 with 1; 6 with 5 |
| Contract → award | 1:1 | 100% of contracts have awardID |
| Contract → transactions | 0:2 | Max 2 per contract (~13,617 total) |
| Contract → milestones | 0:2 | Max 2 per contract (implementation + contract level) |

### 3.5 Which fields support the approved metrics?

| Metric | Required entities | Required fields |
|--------|-------------------|-----------------|
| M-P01 | releases, planning, dim_buyer | ocid, buyer_id, budget_amount, budget_amount_flag |
| M-C01/C02 | releases, tender | ocid, number_of_tenderers, tenderer_count_flag |
| M-S01 | releases, awards, award_suppliers, dim_supplier | ocid, award_value, supplier_id, supplier_id_flag |
| M-V01 | releases, awards | ocid, award_value, award_value_flag |
| M-E01 | releases, tender | ocid, tender_start_date, tender_end_date, date flags |
| M-E02 | releases, tender, awards | ocid, tender_start_date, award_date, date flags, award count |
| M-E03 | releases | ocid, tag |
| M-I01 | releases, contracts | ocid, has_implementation |

---

## 4. Analytical Grains

| Grain | Natural identifier | Cardinality | Parent | Reliable? | Surrogate? | Approved metrics |
|-------|-------------------|-------------|--------|-----------|-----------|-----------------|
| Release | release_id | 108,277 | (OCID) | Yes | No | All (via joins) |
| Process (OCID) | ocid | 98,866 | — | Yes (grouping) | No | M-P01 through M-I01 |
| Tender | release_id (1:1) | 18,408 | Release | Yes | No | M-C01, M-C02, M-E01, M-E02 |
| Award | award_id | 17,417 | Release | Yes (global) | No | M-S01, M-V01, M-E02 |
| Contract | contract_id | 17,043 | Release | Yes (global) | No | M-I01 |
| Transaction | (contract_id, txn_id) | ~13,617 | Contract | Unclear | Yes (SERIAL) | M-I01 (presence) |
| Milestone | (contract_id, ms_id) | ~27,960 | Contract | Unclear | Yes (SERIAL) | Deferred |
| Party/release | (release_id, party_id) | ~216,514 | Release | Yes | Yes (SERIAL) | Supplier extraction |
| Buyer (dim) | buyer_id | 666 | — | Yes | No | M-P01, benchmarking |
| Supplier (dim) | supplier_id | 10,296 | — | Yes | No | M-S01 |

---

## 5. Entity Catalogue

### 5.1 stg.releases — Release staging

| Property | Detail |
|----------|--------|
| Purpose | Source-faithful staging of all OCDS releases |
| Grain | One row per release |
| PK | `release_id` (VARCHAR(64)) |
| FK | `buyer_id` → core.dim_buyer (optional — can enforce in Phase 6) |
| Expected rows | 108,277 |
| Source | `releases[]` top-level fields |
| DQ | party_flag (DQ-18) |
| Metrics | All metrics join through this table for OCID grouping |

### 5.2 stg.planning — Budget/planning data

| Property | Detail |
|----------|--------|
| Purpose | Planning/budget data per release |
| Grain | One row per release (all 108,277 have planning) |
| PK/FK | `release_id` → stg.releases |
| Expected rows | 108,277 |
| Source | `releases[].planning.budget.*` |
| DQ | budget_amount_flag (DQ-06), budget_monetary_flag (DQ-16) |
| Metrics | M-P01 |

### 5.3 stg.tender — Tender data

| Property | Detail |
|----------|--------|
| Purpose | Tender-stage data per release |
| Grain | One row per release with tender data |
| PK/FK | `release_id` → stg.releases |
| Expected rows | 18,408 |
| Source | `releases[].tender.*` |
| DQ | tenderer_count_flag (DQ-03/04/05), date flags (DQ-08/09) |
| Metrics | M-C01, M-C02, M-E01, M-E02 |

### 5.4 stg.awards — Award data

| Property | Detail |
|----------|--------|
| Purpose | Award records per release |
| Grain | One row per award (max 1 per release) |
| PK | `award_id` (VARCHAR(64), globally unique) |
| FK | `release_id` → stg.releases |
| Expected rows | 17,417 |
| Source | `releases[].awards[]` |
| DQ | award_value_flag (DQ-07), award_monetary_flag (DQ-16), award_date_flag (DQ-08/09) |
| Metrics | M-S01, M-V01, M-E02 |

### 5.5 stg.award_suppliers — Award–supplier junction

| Property | Detail |
|----------|--------|
| Purpose | Supplier(s) per award |
| Grain | One row per (award, supplier) pair |
| PK | `award_supplier_pk` (SERIAL) |
| FK | `award_id` → stg.awards |
| Natural key | (award_id, supplier_id) — UNIQUE constraint |
| Expected rows | ~17,441 |
| Source | `releases[].awards[].suppliers[]` |
| Metrics | M-S01 |

### 5.6 stg.contracts — Contract data

| Property | Detail |
|----------|--------|
| Purpose | Contract records per release |
| Grain | One row per contract (max 1 per release) |
| PK | `contract_id` (VARCHAR(64), globally unique) |
| FK | `release_id` → stg.releases; `award_id` → stg.awards |
| Expected rows | 17,043 |
| Source | `releases[].contracts[]` |
| DQ | date flags (DQ-08/09), contract_monetary_flag (DQ-16) |
| Metrics | M-I01 |

### 5.7 stg.transactions — Implementation transactions

| Property | Detail |
|----------|--------|
| Purpose | Implementation transaction data per contract |
| Grain | One row per transaction (max 2 per contract) |
| PK | `transaction_pk` (SERIAL) |
| FK | `contract_id` → stg.contracts |
| Expected rows | ~13,617 |
| Source | `contracts[].implementation.transactions[]` |
| DQ | DQ-11 (no date), DQ-12 (value semantics UNRESOLVED) |
| **CRITICAL** | No `transaction_date` column — universally absent in source. Value semantics unresolved — do NOT sum until DQ-12 resolved. |

### 5.8 stg.milestones — Contract and implementation milestones

| Property | Detail |
|----------|--------|
| Purpose | Milestones from both contract-level and implementation-level sources |
| Grain | One row per milestone |
| PK | `milestone_pk` (SERIAL) |
| FK | `contract_id` → stg.contracts |
| Discriminator | `milestone_source` ('CONTRACT' or 'IMPLEMENTATION') |
| Expected rows | ~27,960 |
| Source | `contracts[].milestones[]` + `contracts[].implementation.milestones[]` |
| DQ | Date quality flags deferred to Phase 5 profiling |

### 5.9 stg.parties — Party records

| Property | Detail |
|----------|--------|
| Purpose | All party records across all releases |
| Grain | One row per (release, party) pair |
| PK | `party_pk` (SERIAL) |
| FK | `release_id` → stg.releases |
| Natural key | (release_id, party_id) — UNIQUE constraint |
| Expected rows | ~216,514 |
| Source | `releases[].parties[]` |
| DQ | supplier_id_flag (DQ-14) |

### 5.10 core.dim_buyer — Buyer dimension

| Property | Detail |
|----------|--------|
| Purpose | Distinct procuring entities |
| Grain | One row per unique buyer_id |
| PK | `buyer_id` (VARCHAR(64)) |
| Expected rows | ~666 |
| Source | Extracted from stg.releases (distinct buyer_id) |
| Columns | buyer_id, buyer_name, buyer_name_raw |

### 5.11 core.dim_supplier — Supplier dimension

| Property | Detail |
|----------|--------|
| Purpose | Distinct suppliers by source supplier_id |
| Grain | One row per unique supplier_id |
| PK | `supplier_id` (VARCHAR(64)) |
| Expected rows | ~10,296 |
| Source | Extracted from stg.parties (distinct supplier-role party_id) |
| DQ | supplier_id_flag (DQ-14): INCOMPLETE for bare NG-BPP- prefix |
| Future | dim_supplier_canonical (DQ-15) deferred to controlled Phase 5+ process |

---

## 6. Release / OCID Strategy

### 6.1 Problem statement

One procurement process (OCID) may have multiple published releases. If we
naively join through all releases, monetary values and counts are doubled.

### 6.2 Approved strategy: Process-snapshot rule

For OCID-level aggregation, select ONE release per OCID:

1. If a release contains all lifecycle tags (`[planning, tender, award,
   contract, implementation]`), it is the definitive snapshot.
2. If multiple releases carry the same tag set, prefer the release with
   the highest `release_id` (latest sequence number).
3. For tag-specific data (e.g., planning budget), take from the release
   whose tag set includes the relevant tag.

### 6.3 Implementation approach

The process-snapshot rule is implemented as `analytics.vw_process_snapshot`
(a VIEW, not a physical table) in Phase 5/7. This preserves all release
history while providing a clean OCID-level analytical surface.

**Rationale for VIEW over physical table:** A materialized view or physical
table would require re-computation on data changes and creates a duplication
risk. A VIEW is always consistent with the staging data and clearly
communicates that the snapshot is a derived analytical construct.

### 6.4 Critical finding: Award ID behaviour

Award IDs and contract IDs are globally unique across the entire dataset —
they are NOT reused across releases for the same OCID. In 554 multi-release
OCIDs with awards in both releases, each release carried a different award
ID (e.g., award `425` in release `2049` vs. award `1755` in release `6895`),
even though the award values were identical.

This means the process-snapshot rule effectively resolves the deduplication
problem by selecting ONE release per OCID. No separate award-level
deduplication logic is needed beyond the snapshot rule.

---

## 7. Supplier Strategy

1. **Primary identity:** `supplier_id` from `parties[].id` for parties with
   a `supplier` role. This is the grouping key for all supplier analysis.

2. **No fuzzy matching:** Suppliers are NOT merged based on name similarity.
   DQ-13 documents that 1,483 supplier IDs map to multiple name variations.
   These are retained as-is.

3. **Incomplete IDs flagged:** Suppliers with bare `NG-BPP-` prefix lacking
   a numeric suffix receive `supplier_id_flag = 'INCOMPLETE'`. These are
   excluded from primary concentration metrics (M-S01) per Phase 3.1
   Correction C-02.

4. **Canonical mapping deferred:** The `dim_supplier_canonical` table
   (DQ-15) requires controlled human-supervised entity resolution.
   The table structure is documented in the DDL as a commented-out
   future extension.

5. **Name preservation:** Original source supplier names are stored in
   `supplier_name_raw` alongside any standardized version.

---

## 8. Data-Quality Flag Placement

| Flag column | Table | Values | DQ issue | Metric impact |
|------------|-------|--------|----------|---------------|
| `party_flag` | stg.releases | NULL / NO_PARTIES | DQ-18 | 20 records excluded from party-linked analyses |
| `budget_amount_flag` | stg.planning | NULL / EXTREME | DQ-06 | EXTREME excluded from M-P01 aggregate budget |
| `budget_monetary_flag` | stg.planning | NULL / ZERO_VALUE | DQ-16 | Zeros excluded from averages/medians |
| `tenderer_count_flag` | stg.tender | NORMAL / ELEVATED / ANOMALOUS | DQ-03/04/05 | ANOMALOUS (65 records) excluded from M-C01/M-C02 |
| `tender_value_monetary_flag` | stg.tender | NULL / ZERO_VALUE | DQ-16 | Zeros excluded from value analyses |
| `tender_start_date_flag` | stg.tender | VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE | DQ-08/09 | Non-VALID excluded from M-E01/M-E02 |
| `tender_end_date_flag` | stg.tender | Same | DQ-08/09 | Non-VALID excluded from M-E01 |
| `award_value_flag` | stg.awards | NULL / EXTREME | DQ-07 | EXTREME excluded from M-V01/M-S01 distribution |
| `award_monetary_flag` | stg.awards | NULL / ZERO_VALUE | DQ-16 | Zeros excluded from value analyses |
| `award_date_flag` | stg.awards | VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE | DQ-08/09 | Non-VALID excluded from M-E02 |
| `contract_monetary_flag` | stg.contracts | NULL / ZERO_VALUE | DQ-16 | Zeros excluded from value analyses |
| `date_signed_flag` | stg.contracts | VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE | DQ-08/09 | Non-VALID excluded from timing metrics |
| `period_start_date_flag` | stg.contracts | Same | DQ-08/09 | Same |
| `period_end_date_flag` | stg.contracts | Same | DQ-08/09 | Same |
| `supplier_id_flag` | stg.parties, core.dim_supplier | NULL / INCOMPLETE | DQ-14 | INCOMPLETE excluded from M-S01 |
| `due_date_flag` | stg.milestones | VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE | Deferred | TBD Phase 5 |
| `date_met_flag` | stg.milestones | Same | Deferred | TBD Phase 5 |
| `transaction_monetary_flag` | stg.transactions | NULL / ZERO_VALUE | DQ-16 | Deferred |

**Design decision:** Date quality uses one flag column PER date attribute
rather than a single `date_quality_flag` column, because different dates
on the same record can have different quality statuses (e.g., a contract's
`date_signed` may be VALID while its `period_end_date` is FUTURE).

---

## 9. Monetary Modelling

- **Data type:** `NUMERIC(30,2)` for all monetary fields (supports values up
  to ₦999,999,999,999,999,999,999,999,999,999.99)
- **Currency:** Stored alongside each amount (uniformly NGN observed)
- **Source preservation:** Original values retained, never imputed
- **Zero handling:** Zero values retained and flagged `ZERO_VALUE` (DQ-16),
  never converted to NULL
- **Cross-stage independence:** No assumption that budget = award = contract.
  Each lifecycle stage has its own independent monetary fields
- **Double-counting prevention:** The process-snapshot rule ensures one
  monetary value per OCID per lifecycle stage

---

## 10. Date Modelling

- **Data type:** `DATE` for event dates; `TIMESTAMPTZ` for release_date
  (publication metadata)
- **Source preservation:** Original date strings parsed to PostgreSQL dates
  with quality flags preserving the classification
- **Quality classification per date:**
  - VALID — plausible operational date
  - PLACEHOLDER — 2001-01-01 (DQ-08)
  - FUTURE — year 2026–2050 (DQ-09)
  - IMPOSSIBLE — year > 2050 (DQ-09, e.g., year 2922)
- **release_date (DQ-10):** All 108,277 releases share the identical value
  `2021-05-03T22:44:00Z`. This is package publication metadata, NOT a
  procurement event date. It must never be used for temporal analysis.
- **Chronological validation:** Duration metrics require end_date ≥ start_date;
  negative durations indicate invalid pairs to be excluded.

---

## 11. Implementation / Transaction Modelling

- **Source location:** `contracts[].implementation.transactions[]`
- **Expected rows:** ~13,617
- **No date field:** DQ-11 confirms transaction date is universally absent.
  The schema has NO `transaction_date` column.
- **Value semantics:** DQ-12 is UNRESOLVED — whether values represent
  cumulative progress or incremental disbursements is unknown. The schema
  stores raw values with a note that aggregation is deferred.
- **Design for future resolution:** The `transaction_value` column stores
  the raw source value. When DQ-12 is resolved, analytical views can
  apply the correct aggregation logic without schema redesign.

---

## 12. Milestone Modelling

- **Source locations:** Two distinct locations in the JSON:
  1. `contracts[].milestones[]` (contract-level milestones)
  2. `contracts[].implementation.milestones[]` (implementation milestones)
- **Design:** Single `stg.milestones` table with a `milestone_source`
  discriminator column ('CONTRACT' or 'IMPLEMENTATION')
- **Date quality:** `dueDate` and `dateMet` quality assessment deferred to
  Phase 5 profiling (27,960 milestone objects not yet fully assessed)
- **Milestone date flag columns** are present but populated as NULL during
  initial loading; Phase 5 profiling will classify them

---

## 13. Normalization Decisions

| Decision | Rationale |
|----------|-----------|
| Planning as separate table | All 108,277 releases have planning; separate table avoids 20+ columns on releases and supports clean budget queries |
| Tender as separate table | Only 18,408 releases have tender; avoids 88% NULL columns on a wide releases table |
| Awards as separate table | Different grain (award-level) with own globally-unique PK; supports supplier junction |
| Contracts as separate table | Different grain with own PK; links to awards via awardID; hosts implementation sub-entities |
| Award-suppliers junction | 6 awards have 5 suppliers — many-to-many relationship requires junction |
| Single milestones table with discriminator | Both contract-level and implementation-level milestones share the same structure; discriminator column distinguishes origin |
| Parties as separate table | Multi-role, multi-release; normalized for supplier dimension extraction |
| Buyer/supplier dimensions in core | Avoid repeating entity names across every staging row; enable clean dimensional joins |
| No physical snapshot table | Process-snapshot rule is a VIEW — preserves all release history |

---

## 14. Proposed Indexing Strategy

Indexes are NOT created in the draft DDL. They will be implemented during
Phase 5 based on query patterns. High-value candidates:

| Index | Table | Column(s) | Rationale |
|-------|-------|-----------|-----------|
| idx_releases_ocid | stg.releases | ocid | Process-snapshot rule; all OCID-level joins |
| idx_planning_budget_flag | stg.planning | budget_amount_flag | M-P01 WHERE filtering |
| idx_tender_count_flag | stg.tender | tenderer_count_flag | M-C01/M-C02 WHERE filtering |
| idx_awards_release | stg.awards | release_id | Join awards to releases for OCID context |
| idx_awards_value_flag | stg.awards | award_value_flag | M-S01/M-V01 WHERE filtering |
| idx_contracts_release | stg.contracts | release_id | Join contracts to releases |
| idx_contracts_award | stg.contracts | award_id | Contract-to-award linkage |
| idx_award_suppliers_award | stg.award_suppliers | award_id | Supplier concentration joins |
| idx_award_suppliers_supplier | stg.award_suppliers | supplier_id | Supplier lookups |
| idx_parties_release | stg.parties | release_id | Release-to-party joins |
| idx_parties_party_id | stg.parties | party_id | Party dimension lookups |

---

## 15. ERD

The entity-relationship diagram is stored at:

- **Mermaid source:** `diagrams/erd/nocopo_erd.mmd` (version-control friendly)
- **Rendered view:** `diagrams/erd/nocopo_erd.md` (viewable in any Markdown renderer)

The ERD shows all 11 entities, their primary/foreign keys, key analytical
columns, flag columns, and cardinalities. It covers both the `stg` (staging)
and `core` (dimension) schemas.

---

## 16. Draft DDL

The draft DDL is stored at:

- **File:** `sql/02_schema/00_draft_core_schema.sql`
- **Status:** DRAFT — NOT EXECUTED
- **Size:** ~600 lines, covering 9 staging tables + 2 core dimension tables
- **Features:**
  - PostgreSQL schemas (`stg`, `core`, `analytics`)
  - Primary keys (natural where reliable, SERIAL surrogates where needed)
  - Foreign keys (release→planning, release→tender, etc.)
  - CHECK constraints on all flag columns
  - Detailed COMMENT ON statements referencing DQ issue IDs
  - Commented-out index proposals
  - Commented-out future extension (dim_supplier_canonical)
  - Commented-out analytical view specifications

---

## 17. Open Issues

### 17.1 DQ-12: Transaction value semantics (UNRESOLVED)

Whether `implementation.transactions[].value` represents cumulative progress
amounts or incremental disbursements remains unconfirmed. The schema stores
raw values. Aggregation views will be defined only after Phase 5 profiling
resolves this question.

### 17.2 Milestone date quality (DEFERRED)

Date quality for 27,960 milestone `dueDate` and `dateMet` values has not
been assessed. Flag columns are present but will be populated during Phase 5
profiling.

### 17.3 Award ID deduplication observation

Phase 3 documentation refers to "deduplicate by award_id within OCID."
Empirical inspection confirms award IDs never repeat across releases for
the same OCID. The process-snapshot rule (select ONE release per OCID)
inherently resolves deduplication. This finding is documented here rather
than modifying the frozen Phase 3 documents.

### 17.4 Tender ID uniqueness

`tender.id` uniqueness across the full dataset has not been profiled. The
current design uses `release_id` as the tender table PK (1:1 relationship).
If tender_id uniqueness is confirmed in Phase 5, it could serve as an
alternative key.

### 17.5 dim_supplier_canonical

The canonical supplier mapping table specified in DQ-15 requires controlled
human-supervised entity resolution. The table structure is documented as a
commented-out future extension in the DDL. It will be created only when
entity resolution rules are formally approved.

---

## 18. Phase 5 Prerequisites

Before Phase 5 implementation can begin:

1. ✅ Phase 3/3.1 documentation frozen
2. ✅ Schema-design gate questions answered (Section 3)
3. ✅ ERD created and documented
4. ✅ Draft DDL created and annotated
5. ⬜ Human review and approval of this design document
6. ⬜ Human review and approval of the ERD
7. ⬜ Human review and approval of the draft DDL
8. ⬜ PostgreSQL local instance accessibility confirmed
9. ⬜ Decision on open issues 17.1–17.5 (or documented acceptance of current treatment)

---

*Document version: 1.0 — 2026-08-20*
*Phase 4 design artifact. No DDL executed. No data loaded.*
