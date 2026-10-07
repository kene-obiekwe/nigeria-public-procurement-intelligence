# Phase 3 Data Quality Decision Log
# Nigeria Public Procurement Intelligence

> **Phase:** 3 - Data-Quality Specification
> **Decision date:** 2026-08-16
> **Approved by:** Project owner
> **Preceding evidence:** docs/phase2_profiling/data_profiling_report.md, docs/phase2_profiling/targeted_validation_report.md
> **This document is SPECIFICATION ONLY. No data has been modified. No schema has been designed.**

---

## Purpose

This document records the approved treatment for every material data-quality issue
identified during Phase 2 profiling and targeted validation. It serves as the
authoritative reference for:

- staging-layer flag column definitions
- metric eligibility rule authoring (see docs/phase3_data_quality/phase3_metric_eligibility.md)
- schema design decisions (Phase 4)
- analytical view construction (Phase 5)
- interpretation caveats in reporting (Power BI, Phase 6+)

All treatment decisions were made by the project owner on 2026-08-16 after reviewing
the Phase 2 findings.

---

## Treatment Category Definitions

| Code | Meaning |
|------|---------|
| RETAIN | Record/value is kept in the database without material alteration |
| FLAG | Record/value is retained but receives a quality-indicator column in staging |
| EXCLUDE_FROM_METRIC | Record/value is excluded from a specific metric eligible population; still present in the database |
| STANDARDIZE | A controlled representation change is applied (e.g. whitespace, casing, data type) without altering business meaning |
| DEFER | Treatment decision is not yet required; will be revisited at a later phase |
| UNRESOLVED | Insufficient evidence to assign a treatment; must be documented as a known limitation |

These categories are **not mutually exclusive**. A record may be simultaneously
RETAIN + FLAG + EXCLUDE_FROM_METRIC for a given metric.

---

## Issue DQ-01 - OCID / Release Repetition (Multi-Release Processes)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-01 |
| **Data field / entity** | 
eleases[].ocid |
| **Observed problem** | 6,280 OCIDs appear in more than one release (maximum 74 releases per OCID; 9,411 excess releases total). The dataset contains 108,277 releases and 98,866 unique OCIDs (procurement processes). Release IDs are unique across the entire dataset; OCIDs are repeated across lifecycle stages of the same process. 108,277 releases ≠ 108,277 unique procurement processes. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 1; docs/phase2_profiling/data_profiling_report.md Section 2 |
| **Severity** | Critical - affects monetary aggregation, process counting, and all OCID-level analytics |
| **Treatment** | RETAIN + DEFER (release-level) |
| **Retained?** | Yes - all 108,277 releases retained |
| **Flagged?** | No flag column required at this stage; OCID-level logic is an analytical-layer concern |
| **Excluded from which metrics?** | N/A at source level; analytical views must apply OCID-level de-duplication rules per metric |
| **Reason** | Multi-release OCIDs are standard OCDS 1.1 lifecycle behaviour. Each release is a valid timestamped event in the procurement lifecycle. Discarding earlier releases would destroy historical information. The analytical layer (Phase 5 views) must define metric-specific rules for whether to aggregate at release or OCID grain. |
| **Known limitation** | Without a confirmed lifecycle sequence/version field, the latest state of a process must be inferred from tag content and/or release index. The OCID with 74 releases warrants individual inspection to confirm it represents legitimate lifecycle history. |
| **Future action** | In Phase 5 analytical views: define OCID-level aggregation rules per metric; create a derived process_snapshot view that selects the analytically appropriate state for each OCID. |

---

## Issue DQ-02 - Planning-Only Releases (83% of Dataset)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-02 |
| **Data field / entity** | 
eleases[].tag |
| **Observed problem** | 89,869 releases (83.0%) carry only the planning tag; they contain no tender, wards, or contracts sub-sections. |
| **Evidence** | docs/phase2_profiling/data_profiling_report.md Section 3 |
| **Severity** | High - defines the eligible population for most analytical pillars |
| **Treatment** | RETAIN |
| **Retained?** | Yes |
| **Flagged?** | No explicit flag required; lifecycle stage is derivable from 	ag field |
| **Excluded from which metrics?** | Exclude from: tender competition analysis, award analysis, contract analysis, supplier concentration, procurement cycle timing. Include in: planning/budget analysis, procuring-entity activity mapping. |
| **Reason** | Planning records represent real procurement intentions and budget commitments. Their absence of later lifecycle stages may reflect: (a) procurement cancelled/deferred; (b) later lifecycle not yet reported; (c) separate processes covered elsewhere in the dataset. No evidence supports treating them as incomplete records requiring imputation. |
| **Known limitation** | It is not possible from the current dataset to distinguish planning records that were never progressed from those progressed under a different OCID or not yet reported. |
| **Future action** | Create a lifecycle-coverage summary metric: percentage of OCIDs progressing from planning to tender to award to contract. |

---

## Issue DQ-03 - numberOfTenderers: Range 1-100 (Normal Population)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-03 |
| **Data field / entity** | 
eleases[].tender.numberOfTenderers |
| **Observed problem** | N/A - documents the approved classification of the normal-range population |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 2 |
| **Severity** | N/A |
| **Treatment** | RETAIN |
| **Retained?** | Yes |
| **Flagged?** | No (tenderer_count_flag = NORMAL) |
| **Excluded from which metrics?** | None - eligible for all competition metrics |
| **Reason** | Values 1-100 are plausible for a Nigerian national competitive bidding context. Median = 2; P95 = 9. |
| **Known limitation** | The field may represent number of bids submitted rather than number of firms that expressed interest. Source documentation does not clarify. |
| **Future action** | Document the field semantics in the analytical data dictionary. Include an interpretation caveat in competition analysis outputs. |

---

## Issue DQ-04 - numberOfTenderers: Elevated Range 101-1,000

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-04 |
| **Data field / entity** | 
eleases[].tender.numberOfTenderers |
| **Observed problem** | 79 records report 101-1,000 tenderers. Above the 99th percentile (24). |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 2 |
| **Severity** | Medium |
| **Treatment** | RETAIN + FLAG |
| **Retained?** | Yes |
| **Flagged?** | Yes - tenderer_count_flag = ELEVATED |
| **Excluded from which metrics?** | Not excluded from primary metrics; excluded from high-confidence sensitivity analyses |
| **Reason** | Cannot confirm these values are errors without source evidence. Flagging enables downstream users to include or exclude as appropriate. |
| **Known limitation** | Without procurement-type context, elevated counts cannot be definitively classified. |
| **Future action** | In competition metric views, offer a primary population (1-100) and a sensitivity population (1-1,000). |

---

## Issue DQ-05 - numberOfTenderers: Extreme Range > 1,000

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-05 |
| **Data field / entity** | 
eleases[].tender.numberOfTenderers |
| **Observed problem** | 65 records report > 1,000 tenderers. Maximum = 90,865. All 65 originate from Federal Ministry of Works and Housing (buyer ID: NG-BPP-BPP-NOC-231001001). The value 6,759 appears repeatedly across unrelated procurement types. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 2.3 |
| **Severity** | Critical |
| **Treatment** | RETAIN + FLAG + EXCLUDE_FROM_METRIC |
| **Retained?** | Yes - original value preserved, not replaced or deleted |
| **Flagged?** | Yes - tenderer_count_flag = ANOMALOUS |
| **Excluded from which metrics?** | Exclude from: primary competition analysis (median tenderers, competition quartiles, distribution charts, single-bidder rates). May be reported separately as a data-quality observation. |
| **Reason** | The pattern (same entity, repeated values across diverse contract types) is inconsistent with any legitimate procurement interpretation. Source values are preserved for auditability. The anomaly does not invalidate these records for other analyses (budget, procuring entity, timing). |
| **Known limitation** | Cannot determine the correct tenderer count without source documentation from the procuring entity. |
| **Future action** | In staging, add tenderer_count_flag column. In analytical views, apply WHERE tenderer_count_flag = NORMAL for primary competition metrics. |

---

## Issue DQ-06 - Extreme Budget Values (>= NGN 1 Trillion)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-06 |
| **Data field / entity** | 
eleases[].planning.budget.amount |
| **Observed problem** | 32 records have budget amounts >= NGN 1 trillion. All are planning-only releases. Three sub-patterns: (a) NPHCDA Hajj vaccine records (~20 records at NGN 3.02T each), (b) Federal Ministry of Works large infrastructure (NGN 5T, NGN 1.97T), (c) FCT Administration (NGN 2.08T). |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 3 |
| **Severity** | Critical |
| **Treatment** | RETAIN + FLAG + EXCLUDE_FROM_METRIC (aggregate budget totals) |
| **Retained?** | Yes |
| **Flagged?** | Yes - budget_amount_flag = EXTREME |
| **Excluded from which metrics?** | Exclude from: total procurement budget aggregations, budget concentration calculations, average budget per procuring entity. Include in: high-value procurement analysis. |
| **Reason for NPHCDA vaccine records:** The approximately 20 records each carry NGN 3.02T for state-level Hajj vaccine procurement. The identical value across all states, combined with the national-scale magnitude, strongly suggests replicated reporting of a single national procurement budget across state procurement contexts, not independent state-level budget commitments. The available source data does not provide sufficient evidence to treat them as independent budgets. No corrected national budget figure will be imputed. |
| **Reason for infrastructure records:** Large infrastructure budgets may be legitimate multi-billion-naira programme budgets. They remain too large for inclusion in general budget aggregation without distortion. |
| **Known limitation** | Without budget appropriation documents, the correct interpretation cannot be confirmed. The treatment is conservative. |
| **Future action** | In staging, add budget_amount_flag column. In analytical views, filter by this flag for aggregate budget metrics. |

---

## Issue DQ-07 - Extreme Award Value: NGN 1.004 Trillion (FCTA Warehouse)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-07 |
| **Data field / entity** | 
eleases[].awards[].value.amount |
| **Observed problem** | One record (OCID: ocds-gyl66f-2-004675) carries an award and tender value of NGN 1,004,166,666,735.23. Buyer: FCTA. Supplier: M/S Turaki Trading Company Ltd. Description: warehouse construction. Active award. Award date: 2022-08-09. Tender and award values match exactly. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 4.2 |
| **Severity** | High |
| **Treatment** | RETAIN + FLAG + EXCLUDE_FROM_METRIC (primary distribution statistics) |
| **Retained?** | Yes |
| **Flagged?** | Yes - award_value_flag = EXTREME |
| **Excluded from which metrics?** | Exclude from: median award value, award distribution benchmarks, procuring entity comparison tables. Include in: high-value procurement analysis, per-OCID reporting. |
| **Reason** | Described as extreme-value observation requiring contextual validation. NGN 1.004 trillion for a warehouse construction project is materially anomalous. However, no internal evidence confirms it is erroneous. The record is not declared fraudulent or incorrect; no correction will be made without external validation. |
| **Known limitation** | Without independent confirmation of the award value from source documents, the record cannot be definitively classified as either valid or erroneous. |
| **Future action** | Flag in staging. Include in a high-value outlier section in the analytical report. |

---

## Issue DQ-08 - Placeholder Date: 2001-01-01

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-08 |
| **Data field / entity** | 	ender.tenderPeriod.startDate (24 occurrences), wards[].date (119), contracts[].dateSigned (77), milestone fields |
| **Observed problem** | The date 2001-01-01T00:00:00Z appears across multiple date fields. Given the dataset covers procurements from approximately 2010 onwards, this date is a known system data-entry artefact indicating date not recorded. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 5; docs/phase2_profiling/data_profiling_report.md Section 6 |
| **Severity** | High |
| **Treatment** | RETAIN (source value) + FLAG + EXCLUDE_FROM_METRIC (timing metrics) |
| **Retained?** | Yes - source date value preserved |
| **Flagged?** | Yes - date_quality_flag = PLACEHOLDER |
| **Excluded from which metrics?** | Exclude from: tender duration calculations, procurement cycle timing, award-to-tender lag, contract period analysis |
| **Reason** | 2001-01-01 predates the observable data period by approximately 9 years and appears systematically across diverse procurement processes. Treatment as a system default is the most defensible interpretation. |
| **Known limitation** | A very small number of genuine contracts from 2001 (if any exist) would be incorrectly flagged. |
| **Future action** | In staging date parsing, set date_quality_flag = PLACEHOLDER for any date with year 2001 and month-day 01-01. |

---

## Issue DQ-09 - Date Anomaly: Year 2922 and Other Extreme Future Dates

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-09 |
| **Data field / entity** | wards[].date (year 2922, year 2033); 	ender.tenderPeriod.startDate (up to 2029); contracts[].period.endDate (up to 2027) |
| **Observed problem** | At least one award date of 2922-08-26 (almost certainly 2022-08-26). One award date of year 2033. Multiple tender/contract period dates in 2026-2029. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 5.3 |
| **Severity** | High for year-2922 (clear error); Medium for 2026-2029 (ambiguous) |
| **Treatment** | RETAIN (source value) + FLAG + EXCLUDE_FROM_METRIC (timing calculations) |
| **Retained?** | Yes |
| **Flagged?** | Yes - date_quality_flag = IMPOSSIBLE (year > 2050); date_quality_flag = FUTURE (year 2026-2050) |
| **Excluded from which metrics?** | Exclude from: any timing or duration metric requiring a valid date |
| **Reason** | Year 2922 is an impossible procurement date. Year 2033 is implausible for a 2021-published dataset. Dates 2026-2029 may be legitimate (multi-year contract periods) but are flagged pending confirmation. |
| **Known limitation** | Some legitimate future-dated contract periods may carry a FUTURE flag. |
| **Future action** | Define date quality tiers: IMPOSSIBLE (year > 2050); FUTURE (year 2026-2050); VALID otherwise. Apply to all seven date fields in staging. |

---

## Issue DQ-10 - Release-Level Date Represents Package Publication Date

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-10 |
| **Data field / entity** | 
eleases[].date |
| **Observed problem** | All 108,277 releases carry date = 2021-05-03T22:44:00Z - the OCDS package publication date, not the individual procurement event date. |
| **Evidence** | docs/phase2_profiling/data_profiling_report.md Section 4; docs/phase2_profiling/targeted_validation_report.md Section 5 |
| **Severity** | High - affects any time-series or trend analysis |
| **Treatment** | RETAIN (accurately represents publication metadata) |
| **Retained?** | Yes |
| **Flagged?** | No flag needed - the fields meaning is now understood and documented |
| **Excluded from which metrics?** | Exclude from: procurement event timing, time-series trend analysis, year-of-procurement analysis |
| **Reason** | The field is correct OCDS behaviour; it is the release publication date. The appropriate analytical dates are inside tender, awards[], and contracts[]. |
| **Known limitation** | Full temporal analysis requires valid internal event dates, which have significant null rates (47.7% for tender start, 15.1% for award date). |
| **Future action** | In all analytical views, use a priority chain of internal event dates for temporal analysis. Document the date-priority hierarchy in the metric eligibility specification. |

---

## Issue DQ-11 - Implementation Transaction Dates: Universally Absent

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-11 |
| **Data field / entity** | contracts[].implementation.transactions[].date |
| **Observed problem** | 13,617 transaction objects exist; zero contain a date field. All 13,617 contain a value field. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 6 |
| **Severity** | High |
| **Treatment** | RETAIN (transactions retained for value analysis) |
| **Retained?** | Yes |
| **Flagged?** | N/A - absence of the field is itself the documented characteristic |
| **Excluded from which metrics?** | Exclude from: payment timeline analysis, days-to-payment metrics, payment disbursement trend analysis |
| **Reason** | Transaction dates are absent across 100% of transaction objects. Fabricating dates is not permissible. This is documented as a dataset limitation. |
| **Known limitation** | Payment timing - a key procurement efficiency indicator - cannot be computed from this dataset. |
| **Future action** | Frame implementation analysis as a reporting-coverage metric: percentage of contracts with implementation records and total reported payment values. Assess milestone date quality in Phase 4 if implementation metrics are required. |

---

## Issue DQ-12 - Implementation Transaction Value Semantics Unclear

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-12 |
| **Data field / entity** | contracts[].implementation.transactions[].value |
| **Observed problem** | All 13,617 transactions have a value object. Whether values represent cumulative payments, instalments, progress certificates, or another concept is unclear. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 6.2 |
| **Severity** | Medium |
| **Treatment** | RETAIN + DEFER |
| **Retained?** | Yes |
| **Flagged?** | Deferred - flag type to be determined after semantic investigation |
| **Excluded from which metrics?** | Not excluded at this stage |
| **Reason** | Transaction values are present and populated; their business meaning requires confirmation before inclusion in payment or disbursement metrics. |
| **Known limitation** | If transaction values represent cumulative totals, summing them per contract would overcount actual disbursements. |
| **Future action** | In Phase 4 ingestion, profile transaction value distributions relative to award values. Document finding before including in any financial metric. |

---

## Issue DQ-13 - Supplier ID to Multiple Names (1,483 cases)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-13 |
| **Data field / entity** | parties[role=supplier].id and parties[role=supplier].name |
| **Observed problem** | 1,483 supplier IDs are associated with more than one distinct name. Most appear to be formatting/abbreviation variants of the same legal entity. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 7.2 |
| **Severity** | Medium |
| **Treatment** | RETAIN (source values) + DEFER (canonical mapping specification) |
| **Retained?** | Yes - both source ID and source name preserved |
| **Flagged?** | No flag at source level; entity resolution is an analytical-layer concern |
| **Excluded from which metrics?** | No current exclusion; analytical views group by supplier ID as the primary key |
| **Reason** | Name variation is expected in procurement records. Supplier ID is a more stable identifier than the name. |
| **Known limitation** | Supplier concentration results at name level will differ from results at ID level. ID level is preferred. |
| **Future action** | Create dim_supplier_canonical mapping table in Phase 4 staging as specified in DQ-15. |

---

## Issue DQ-14 - Supplier Name to Multiple IDs (571 cases)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-14 |
| **Data field / entity** | parties[role=supplier].name and parties[role=supplier].id |
| **Observed problem** | 571 supplier names are associated with more than one distinct ID. Many involve a bare NG-BPP- identifier (incomplete) paired with a proper NG-BPP-BPP-CI-NNNN identifier. |
| **Evidence** | docs/phase2_profiling/targeted_validation_report.md Section 7.3 |
| **Severity** | Medium |
| **Treatment** | RETAIN (source values) + FLAG (incomplete identifiers) |
| **Retained?** | Yes |
| **Flagged?** | Yes - supplier_id_flag = INCOMPLETE for records where supplier ID matches the pattern NG-BPP- without a numeric suffix |
| **Excluded from which metrics?** | Records with incomplete IDs should be treated with caution in supplier concentration analysis |
| **Reason** | A bare NG-BPP- identifier without a sequential suffix does not uniquely identify a supplier. |
| **Known limitation** | Without access to the BPP supplier registration database, incomplete IDs cannot be resolved. |
| **Future action** | In staging, add supplier_id_flag for incomplete identifiers. Exclude from primary concentration metrics or include as an unresolved category. |

---

## Issue DQ-15 - Canonical Supplier Mapping Table (Specification Only)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-15 |
| **Data field / entity** | Supplier identity (cross-field) |
| **Observed problem** | No canonical supplier identity exists in the source data; resolution requires a derived mapping. |
| **Evidence** | DQ-13, DQ-14; docs/phase2_profiling/targeted_validation_report.md Section 7 |
| **Severity** | Medium (manageable if analytical views use ID as primary key) |
| **Treatment** | DEFER - specification only |
| **Retained?** | N/A |
| **Flagged?** | N/A |
| **Excluded from which metrics?** | N/A |
| **Reason** | The canonical mapping table requires Phase 4 implementation work. The specification is provided so Phase 4 can implement it correctly. |
| **Known limitation** | Any automated resolution carries risk of incorrect merges. All automated resolution must be auditable. |
| **Future action** | In Phase 4 staging, create dim_supplier_canonical with columns: source_supplier_id, source_supplier_name, canonical_supplier_id, canonical_supplier_name, resolution_status (CONFIRMED / PROBABLE / UNRESOLVED), resolution_method (MANUAL / ID_MATCH / FORMATTING_NORMALIZATION), confidence (HIGH / MEDIUM / LOW), notes. Do NOT merge suppliers using fuzzy name matching. |

---

## Issue DQ-16 - Zero Monetary Values

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-16 |
| **Data field / entity** | planning.budget.amount (561 zeros), 	ender.value.amount (1,259 zeros), wards[].value.amount (268 zeros) |
| **Observed problem** | Exact zero values appear across all three monetary fields. May represent legitimate zero-value contracts, placeholder entries, in-kind procurements, or framework agreements. |
| **Evidence** | docs/phase2_profiling/data_profiling_report.md Section 5 |
| **Severity** | Medium |
| **Treatment** | RETAIN + FLAG |
| **Retained?** | Yes - do not replace zero with NULL |
| **Flagged?** | Yes - monetary_flag = ZERO_VALUE |
| **Excluded from which metrics?** | Exclude from: average award value, average tender value. Include in: counts and coverage metrics. Decision is metric-specific. |
| **Reason** | Zero cannot be automatically assumed to mean missing. Some legitimate procurement categories may have zero monetary values. |
| **Known limitation** | Without additional context, the semantic meaning of zero cannot be determined for individual records. |
| **Future action** | Profile zero-value records by procurement method and buyer in Phase 4 to determine whether a pattern justifies reclassification for specific metrics. |

---

## Issue DQ-17 - Supplier Identifier Scheme Uniformity (Unconfirmed)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-17 |
| **Data field / entity** | parties[].identifier.scheme |
| **Observed problem** | All observed party identifier schemes use NG-BPP. This was observed in initial profiling but was not confirmed across all 108,277 releases. |
| **Evidence** | docs/phase2_profiling/data_profiling_report.md Section 7 |
| **Severity** | Low |
| **Treatment** | DEFER |
| **Retained?** | N/A |
| **Flagged?** | N/A |
| **Excluded from which metrics?** | N/A |
| **Reason** | If all identifiers share the same scheme, the scheme column adds no analytical value. If multiple schemes exist, cross-scheme entity matching would need special handling. |
| **Known limitation** | A full scan across all 108,277 releases was not performed for this field. |
| **Future action** | In Phase 4 ingestion, perform a GROUP BY identifier_scheme check. If uniform, document and proceed. If mixed, escalate to human review. |

---

## Issue DQ-18 - Releases with No Parties Array (20 Records)

| Attribute | Detail |
|-----------|--------|
| **Issue ID** | DQ-18 |
| **Data field / entity** | 
eleases[].parties |
| **Observed problem** | 20 releases have no parties array or an empty array. These records cannot be linked to buyer/supplier entities through the standard OCDS party mechanism. |
| **Evidence** | docs/phase2_profiling/data_profiling_report.md Section 7 |
| **Severity** | Low (0.02% of the dataset) |
| **Treatment** | RETAIN + FLAG |
| **Retained?** | Yes |
| **Flagged?** | Yes - party_flag = NO_PARTIES |
| **Excluded from which metrics?** | Exclude from: buyer-level analysis, supplier concentration, any metric requiring a party link |
| **Reason** | 20 records is too small to materially affect analysis. Retaining and flagging is proportionate. |
| **Known limitation** | These records may still contain valid monetary values that should be excluded from entity-linked aggregations. |
| **Future action** | In staging ingestion, flag these 20 records. Inspect manually to determine whether the buyer field provides sufficient entity linkage. |

---

## Summary Matrix

| Issue ID | Entity | Severity | RETAIN | FLAG | EXCLUDE_FROM_METRIC | DEFER | UNRESOLVED |
|----------|--------|----------|--------|------|---------------------|-------|------------|
| DQ-01 | OCID repetition | Critical | Yes | - | - | Yes | - |
| DQ-02 | Planning-only releases | High | Yes | - | Yes (later-stage metrics) | - | - |
| DQ-03 | numberOfTenderers 1-100 | N/A | Yes | - | - | - | - |
| DQ-04 | numberOfTenderers 101-1,000 | Medium | Yes | Yes | - | - | - |
| DQ-05 | numberOfTenderers > 1,000 | Critical | Yes | Yes | Yes | - | - |
| DQ-06 | Budget >= NGN 1 trillion | Critical | Yes | Yes | Yes | - | - |
| DQ-07 | Award NGN 1.004T (FCTA) | High | Yes | Yes | Yes | - | - |
| DQ-08 | Placeholder date 2001-01-01 | High | Yes | Yes | Yes | - | - |
| DQ-09 | Year 2922 / extreme future dates | High | Yes | Yes | Yes | - | - |
| DQ-10 | Release date = publication batch | High | Yes | - | Yes (temporal metrics) | - | - |
| DQ-11 | Transaction dates absent | High | Yes | - | Yes (payment timing) | - | - |
| DQ-12 | Transaction value semantics unclear | Medium | Yes | - | - | Yes | - |
| DQ-13 | Supplier ID to multiple names | Medium | Yes | - | - | Yes | - |
| DQ-14 | Supplier name to multiple IDs | Medium | Yes | Yes | - | - | - |
| DQ-15 | Canonical supplier mapping spec | Medium | N/A | N/A | N/A | Yes | - |
| DQ-16 | Zero monetary values | Medium | Yes | Yes | Yes (avg metrics) | - | - |
| DQ-17 | Identifier scheme uniformity | Low | N/A | N/A | N/A | Yes | - |
| DQ-18 | No parties array (20 records) | Low | Yes | Yes | Yes | - | - |

---

## Flag Column Specification for Phase 4 Staging

The following flag columns must be created in the staging layer. This is a specification only;
columns are not yet created.

| Column name | Applied to | Values | Meaning |
|-------------|-----------|--------|---------|
| tenderer_count_flag | tender records | NORMAL / ELEVATED / ANOMALOUS | Quality tier for numberOfTenderers |
| budget_amount_flag | planning records | NULL (normal) / EXTREME | Budget amount quality |
| award_value_flag | award records | NULL (normal) / EXTREME | Award value quality |
| date_quality_flag | all date fields | VALID / PLACEHOLDER / FUTURE / IMPOSSIBLE | Date validity tier |
| supplier_id_flag | supplier party records | NULL (normal) / INCOMPLETE | Supplier identifier completeness |
| monetary_flag | monetary fields | NULL (normal) / ZERO_VALUE | Zero monetary value indicator |
| party_flag | release level | NULL (normal) / NO_PARTIES | Absence of parties array |

---

*Document version: 1.1 - 2026-08-18. Phase 3.1 correction pass applied.*
*Version 1.0 approved by project owner on 2026-08-16.*
*No data has been modified. No schema has been designed.*
*Next reference: docs/phase3_data_quality/phase3_metric_eligibility.md, docs/phase3_data_quality/phase3_data_dictionary.md*
