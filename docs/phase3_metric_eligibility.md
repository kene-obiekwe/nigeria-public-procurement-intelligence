# Phase 3 Metric Eligibility and Analytical Rules
# Nigeria Public Procurement Intelligence

> **Phase:** 3 - Metric Eligibility Specification
> **Decision date:** 2026-08-16
> **Approved by:** Project owner
> **Preceding documents:** docs/phase3_data_quality_decision_log.md, docs/targeted_validation_report.md
> **This document is SPECIFICATION ONLY. No SQL has been written. No schema has been designed.**

---

## Purpose

This document specifies:

1. The five analytical pillars and their metric eligibility rules.
2. The analytical grain rules - when to use release-level, OCID-level, award-level, contract-level, supplier-level, and buyer-level analysis.
3. The formal metric eligibility framework with worked examples.
4. Double-counting risks and the rules to prevent them.

This document is the primary reference for Phase 5 analytical-view authors.

---

## Section 1: Analytical Grain Rules

### 1.1 The Problem

The NOCOPO dataset contains 108,277 releases but only 98,866 unique OCIDs. Each
OCID represents one procurement process. The 6,280 OCIDs that appear in multiple
releases create a risk: if a monetary value is present in each release for a given OCID,
naively summing releases will double-count that value.

### 1.2 Analytical Grain Definitions

**Release level**
The raw unit of observation. Use at release level when:
- Counting the number of disclosure events or notifications published.
- Auditing data quality across releases.
- Tracking release frequency per procuring entity.
- Computing missingness rates and data coverage.

Do NOT aggregate monetary values at release level without a deduplication rule.

---

**Procurement-process / OCID level**
The procurement process is identified by OCID. Use at OCID level when:
- Counting the number of distinct procurement processes.
- Measuring planning-to-award conversion rates.
- Measuring procurement cycle durations (tender open to award).
- Computing aggregate procurement values (budget, tender, award).
- Analysing competition (number of tenderers per process).

Rule: For each OCID, select the analytically appropriate release(s) per the
process-snapshot rule defined below.

**Process-snapshot rule:**
For a given OCID, the preferred release for each lifecycle section is:
- Planning data: from the release with the most planning-inclusive tag set.
- Tender data: from the release that includes the 	ender tag.
- Award data: from the release that includes the ward tag.
- Contract data: from the release that includes the contract tag.
- Implementation data: from the release that includes the implementation tag.

If a release carries all lifecycle tags (planning, tender, award, contract, implementation),
it is treated as the definitive snapshot for all fields.

If multiple releases carry the same tag, prefer the release with the highest index
(latest by sequence) for that tag, unless there is analytical reason to prefer otherwise.

This rule prevents double-counting monetary values across the lifecycle without discarding
historical information.

---

**Award level**
An award is a separate analytical object within a procurement process. Use at award level when:
- Counting awards issued.
- Summarising awarded values by supplier or procuring entity.
- Measuring award cancellation rates.
- Analysing supplier concentration.

Note: One OCID may have multiple awards (e.g. multi-lot procurements). Aggregating
awards to OCID level requires awareness of this.

---

**Contract level**
A contract is issued following an award. Use at contract level when:
- Measuring contract status (active, terminated, cancelled).
- Measuring contract durations (period start to end).
- Analysing implementation data (transactions, milestones).
- Measuring reporting coverage (contracts with implementation records).

---

**Supplier level**
Use at supplier level when:
- Measuring supplier concentration (share of award value).
- Counting awards per supplier.
- Profiling supplier activity by sector or procuring entity.
- Identifying single-supplier patterns.

Primary grain: supplier ID (see DQ-13, DQ-14, DQ-15 for entity resolution rules).
Do not aggregate by supplier name without normalisation.

---

**Buyer / procuring-entity level**
Use at buyer level when:
- Measuring procuring entity activity (volume, value, frequency).
- Comparing competition levels across entities.
- Measuring entity-level data quality and reporting completeness.
- Identifying planning-only entities vs. entities with full lifecycle.

Primary grain: buyer ID from 
eleases[].buyer.id.

---

### 1.3 Double-Counting Prevention Rules

| Scenario | Risk | Rule |
|----------|------|------|
| Summing budget amounts across all releases | A repeated OCID with a budget in each release would be counted multiple times | Apply process-snapshot rule; take budget from ONE release per OCID |
| Summing award values across releases | Same award value may appear in the award release and the implementation release for the same OCID | Deduplicate at award ID level within an OCID before aggregation |
| Summing transaction values | May represent cumulative rather than incremental payments (DQ-12) | Do not sum transaction values until semantic meaning is confirmed in Phase 4 |
| Counting procurement processes | Each OCID = one process; counting releases would overcount | Always count distinct OCIDs, not total releases |
| NPHCDA vaccine budgets | ~20 planning releases with the same national-scale budget | Apply budget_amount_flag = EXTREME exclusion (DQ-06) |

---

## Section 2: Five Analytical Pillars

### Pillar 1: Procurement Planning and Market Intelligence

**Analytical objective:**
Understand the scale, distribution, and reporting completeness of procurement planning.
Map the universe of planned procurements to procuring entities, sectors, and value ranges.

**Primary unit of analysis:** OCID (procurement process), buyer/procuring entity

**Required source fields:**
- 
eleases[].ocid
- 
eleases[].buyer.id, 
eleases[].buyer.name
- 
eleases[].planning.budget.amount
- 
eleases[].planning.budget.currency
- 
eleases[].planning.budget.description
- 
eleases[].planning.budget.project
- 
eleases[].tag
- 
eleases[].tender.procurementMethodDetails

**Minimum data requirements:**
- Record must have a planning section.
- Budget amount must be non-null and non-negative.
- Buyer must be identified.

**Valid population:**
All releases with planning tag (108,277 releases / 108,277 OCIDs at planning stage).

**Exclusions:**
- Records with udget_amount_flag = EXTREME (DQ-06) from aggregate budget totals.
- Records with monetary_flag = ZERO_VALUE from average budget calculations.
- Records with party_flag = NO_PARTIES from buyer-level analysis.

**Flags to apply:**
- udget_amount_flag
- monetary_flag
- party_flag

**Known limitations:**
- 83% of releases are planning-only; the planning universe is therefore much larger
  than the contracting universe, and planning-to-award conversion rates will be low.
- Planning budget may represent allocation, not final spend.
- NPHCDA vaccine records inflate the aggregate budget; their exclusion is mandatory
  for meaningful total-budget figures.

**Potential double-counting risks:**
- Budgets repeated across multi-release OCIDs: apply process-snapshot rule.
- NPHCDA per-state budget replication: apply budget_amount_flag exclusion.

**Analytical grain:** OCID-level for value aggregation; buyer-level for entity comparisons.

---

### Pillar 2: Competition and Tendering

**Analytical objective:**
Measure the competitive depth of Nigerian federal procurement. Identify procurement
processes with low competition, sector or entity patterns in competition levels, and
trends in tendering participation.

**Primary unit of analysis:** OCID (procurement process), tender

**Required source fields:**
- 
eleases[].ocid
- 
eleases[].buyer.id, 
eleases[].buyer.name
- 
eleases[].tender.numberOfTenderers
- 
eleases[].tender.procurementMethod
- 
eleases[].tender.procurementMethodDetails
- 
eleases[].tender.value.amount
- 
eleases[].tender.status
- 
eleases[].tender.tenderPeriod.startDate
- 
eleases[].tender.tenderPeriod.endDate

**Minimum data requirements:**
- Record must have a 	ender section.
- 
umberOfTenderers must be non-null (confirmed: 0 null in 18,408 tender releases).
- Tender must have a valid status (not null).

**Valid population (primary):**
Tender releases with 	enderer_count_flag = NORMAL (numberOfTenderers 1-100).

**Valid population (sensitivity):**
Tender releases with 	enderer_count_flag IN (NORMAL, ELEVATED) (numberOfTenderers 1-1,000).

**Exclusions:**
- Records with 	enderer_count_flag = ANOMALOUS (numberOfTenderers > 1,000 / DQ-05) from primary metrics.
- Planning-only releases (no tender section) from all competition metrics.

**Flags to apply:**
- 	enderer_count_flag

**Known limitations:**
- 65 Federal Ministry of Works records carry systematically anomalous tenderer counts.
  These are excluded from primary competition statistics and documented separately.
- The field meaning (bids submitted vs. expressions of interest) is unconfirmed.
- Only 18,408 of 108,277 releases (17%) have tender data; competition analysis covers
  a minority of the full procurement universe.

**Potential double-counting risks:**
- A procurement process with multiple releases may have a tender section in more than
  one release. Apply process-snapshot rule: use ONE tender record per OCID.

**Analytical grain:** OCID-level (one tender per process); buyer-level for entity comparisons.

---

### Pillar 3: Supplier and Market Concentration

**Analytical objective:**
Identify the degree of supplier concentration in Nigerian federal procurement.
Measure the share of award value attributable to the top suppliers. Identify
single-supplier procurement patterns and potential over-reliance on specific firms.

**Primary unit of analysis:** Supplier (by supplier ID), award

**Required source fields:**
- 
eleases[].awards[].id
- 
eleases[].awards[].value.amount
- 
eleases[].awards[].value.currency
- 
eleases[].awards[].suppliers[].id
- 
eleases[].awards[].suppliers[].name
- 
eleases[].awards[].status
- 
eleases[].buyer.id
- 
eleases[].tender.procurementMethodDetails

**Minimum data requirements:**
- Award must have a non-null, non-zero value.
- Award must have at least one supplier with a non-null, non-incomplete ID.
- Award status must be ctive (exclude cancelled and unsuccessful awards from value concentration).

**Valid population:**
Active awards with:
- ward_value_flag IS NULL (not extreme) for primary concentration metrics.
- supplier_id_flag IS NULL or INCOMPLETE (with appropriate caveats for incomplete IDs).

**Exclusions:**
- Award with ward_value_flag = EXTREME (DQ-07, FCTA warehouse) from primary distribution metrics.
  Include in high-value procurement analysis separately.
- Awards with monetary_flag = ZERO_VALUE from value concentration metrics.
- Awards where all associated suppliers have incomplete IDs.

**Flags to apply:**
- ward_value_flag
- supplier_id_flag
- monetary_flag

**Known limitations:**
- 1,483 supplier IDs map to multiple names; results may overstate the number of distinct
  suppliers if the same entity uses multiple name formats.
- Incomplete NG-BPP- IDs (DQ-14) represent an entity-resolution gap.
- Supplier concentration figures should be caveated as lower-bound estimates of actual
  concentration, pending canonical entity resolution.

**Potential double-counting risks:**
- A supplier winning awards across multiple releases of the same OCID would be
  double-counted if awards are not deduplicated at award ID level. Rule: deduplicate
  by award ID across all releases for the same OCID before aggregating supplier values.

**Analytical grain:** Award-level for individual awards; supplier-level for concentration analysis.

---

### Pillar 4: Contracting and Value Analysis

**Analytical objective:**
Understand the financial scale and distribution of contracts awarded. Measure
the relationship between budget, tender value, and award value. Identify significant
value deviations and budget utilisation patterns.

**Primary unit of analysis:** OCID (procurement process), award

**Required source fields:**
- 
eleases[].ocid
- 
eleases[].planning.budget.amount
- 
eleases[].tender.value.amount
- 
eleases[].awards[].value.amount
- 
eleases[].contracts[].value.amount (if present)
- 
eleases[].buyer.id
- 
eleases[].tender.procurementMethodDetails
- 
eleases[].awards[].suppliers[].id
- 
eleases[].awards[].date

**Minimum data requirements:**
- At minimum, an award value must be present for award-level analysis.
- For budget-to-award analysis, both budget and award values must be non-null.
- Currency must be NGN (confirmed: all observed amounts are NGN).

**Valid population:**
For budget-to-award comparison:
- Records where planning budget and award value are both non-null, non-zero.
- udget_amount_flag IS NULL (exclude extreme budget records from aggregate comparisons).
- ward_value_flag IS NULL (exclude extreme award records from distribution benchmarks).

**Exclusions:**
- Records with udget_amount_flag = EXTREME from aggregate budget-to-award comparisons.
- Records with ward_value_flag = EXTREME from distribution benchmarks.
- Records with monetary_flag = ZERO_VALUE from average value calculations.

**Known limitations:**
- Budget, tender value, and award value are not guaranteed to be comparable. In OCDS,
  these represent different stages of the procurement process. The profiling confirmed
  that some tender values equal award values exactly, suggesting the tender value field
  may sometimes be populated retroactively with the award value.
- No FX conversion is needed (all NGN), but value-of-money comparisons over time
  require NGN deflators that are outside the current dataset.

**Potential double-counting risks:**
- Budgets and award values appearing in multiple releases for the same OCID.
  Apply process-snapshot rule. Take ONE budget value and ONE award value per OCID.

**Analytical grain:** OCID-level for value comparisons; buyer/method-level for segment analysis.

---

### Pillar 5: Procurement Process Efficiency

**Analytical objective:**
Measure the time efficiency of the Nigerian federal procurement cycle.
Identify entities and sectors with fast or slow procurement processes.
Measure the proportion of processes reaching each lifecycle stage.

**Primary unit of analysis:** OCID (procurement process)

**Required source fields:**
- 
eleases[].ocid
- 
eleases[].tender.tenderPeriod.startDate
- 
eleases[].tender.tenderPeriod.endDate
- 
eleases[].awards[].date
- 
eleases[].contracts[].dateSigned
- 
eleases[].contracts[].period.startDate
- 
eleases[].contracts[].period.endDate
- 
eleases[].buyer.id
- 
eleases[].tag

**Minimum data requirements:**
For any specific timing metric, both the start and end date for that interval must be:
- Non-null.
- date_quality_flag = VALID (not PLACEHOLDER, not FUTURE, not IMPOSSIBLE).
- Forming a valid chronological sequence (end date > start date; no negative durations).

**Valid population:**
For tender duration (startDate to endDate):
- Both tender period dates must be non-null and VALID.
- End date must be >= start date.

For award lag (tender start to award date):
- Tender start date and award date must both be non-null and VALID.
- Award date must be >= tender start date.

For contract signature lag (award date to dateSigned):
- Both dates non-null and VALID.
- dateSigned >= award date.

**Exclusions:**
- All records where the relevant date has date_quality_flag != VALID.
- All records with placeholder dates (2001-01-01) - DQ-08.
- All records with extreme future dates (year > 2050) - DQ-09.
- All records producing negative durations.
- Release-level date field must NOT be used for any timing metric - DQ-10.

**Known limitations:**
- Tender start date is null for 47.7% of tender releases; timing analysis covers
  only ~52% of tender releases.
- Transaction dates are universally absent (DQ-11); payment timing cannot be computed.
- Milestone dueDate/dateMet may provide implementation timing signals but has not
  yet been quality-assessed (planned for Phase 4).
- Future-dated contract period ends (2026-2027) may be legitimate multi-year contracts
  or data errors; they are flagged as FUTURE and excluded from duration calculations
  pending validation.

**Potential double-counting risks:**
- A procurement process with multiple releases may contain duplicate date fields.
  Apply process-snapshot rule: use dates from the release that covers the relevant lifecycle stage.

**Analytical grain:** OCID-level for cycle time; buyer-level for entity comparison.

---

## Section 3: Metric Eligibility Framework

Each metric in the eventual analytical layer must have a defined eligibility specification.
The template below defines the required fields. Examples are provided for key metrics.

### Metric Template

| Field | Description |
|-------|-------------|
| Metric ID | Unique identifier (e.g. M-C01) |
| Metric name | Human-readable name |
| Pillar | Which analytical pillar this belongs to |
| Business question | The question the metric answers |
| Analytical grain | The unit at which this is computed |
| Numerator | What is being counted or summed |
| Denominator | Divisor if applicable |
| Required fields | Source fields that must be non-null |
| Eligibility conditions | Records that must be present |
| Exclusion conditions | Records that must be absent or filtered out |
| Anomaly flags | Which DQ flags affect this metric |
| Aggregation rule | How to aggregate across releases for the same OCID |
| Double-counting risk | Specific risk and mitigation |
| Interpretation caveat | Important caveats for consumers of this metric |

---

### M-P01: Total Planned Procurement Budget (by Procuring Entity)

| Field | Value |
|-------|-------|
| Metric ID | M-P01 |
| Metric name | Total planned procurement budget per procuring entity |
| Pillar | Pillar 1 - Procurement Planning and Market Intelligence |
| Business question | Which procuring entities have the largest planned procurement budgets? |
| Analytical grain | Buyer / procuring entity |
| Numerator | SUM of planning.budget.amount across all eligible OCIDs for the entity |
| Denominator | N/A |
| Required fields | planning.budget.amount (non-null, non-negative); uyer.id (non-null) |
| Eligibility conditions | Release has a planning section; budget amount is non-null and >= 0 |
| Exclusion conditions | udget_amount_flag = EXTREME; monetary_flag = ZERO_VALUE; party_flag = NO_PARTIES |
| Anomaly flags | budget_amount_flag, monetary_flag, party_flag |
| Aggregation rule | One budget value per OCID (process-snapshot rule); then SUM across OCIDs per buyer |
| Double-counting risk | Multi-release OCIDs may repeat the budget value. Mitigation: take ONE budget per OCID before summing. NPHCDA per-state replication: mitigation via budget_amount_flag exclusion. |
| Interpretation caveat | This is a planned budget, not actual spend. Extreme values excluded. Result represents a lower bound on total visible planned procurement. |

---

### M-C01: Median Number of Tenderers

| Field | Value |
|-------|-------|
| Metric ID | M-C01 |
| Metric name | Median number of tenderers (competition depth) |
| Pillar | Pillar 2 - Competition and Tendering |
| Business question | What is the typical level of competition in federal procurement tenders? |
| Analytical grain | OCID (one tender per process) |
| Numerator | MEDIAN of 	ender.numberOfTenderers across eligible tender processes |
| Denominator | N/A |
| Required fields | 	ender.numberOfTenderers (non-null - confirmed: 0 null) |
| Eligibility conditions | Release has a tender section; 	enderer_count_flag = NORMAL |
| Exclusion conditions | 	enderer_count_flag IN (ELEVATED, ANOMALOUS) for primary median; 	enderer_count_flag = ANOMALOUS only for sensitivity median |
| Anomaly flags | tenderer_count_flag |
| Aggregation rule | One tender record per OCID (process-snapshot rule); then compute MEDIAN across OCIDs |
| Double-counting risk | Low - numberOfTenderers is a property of a single tender event; not subject to release-level duplication if deduplicated correctly. |
| Interpretation caveat | Primary metric uses numberOfTenderers = 1-100 (99% of normal-range population). 65 records from Federal Ministry of Works are excluded. Median = 2 in normal population, indicating low competition across most processes. |

---

### M-C02: Single-Bidder Rate

| Field | Value |
|-------|-------|
| Metric ID | M-C02 |
| Metric name | Single-bidder procurement rate |
| Pillar | Pillar 2 - Competition and Tendering |
| Business question | What proportion of tenders received only one bid? |
| Analytical grain | OCID (one tender per process) |
| Numerator | COUNT of OCIDs where 	ender.numberOfTenderers = 1 |
| Denominator | COUNT of all eligible OCIDs with a tender record and 	enderer_count_flag = NORMAL |
| Required fields | 	ender.numberOfTenderers (non-null) |
| Eligibility conditions | 	enderer_count_flag = NORMAL |
| Exclusion conditions | 	enderer_count_flag IN (ELEVATED, ANOMALOUS) |
| Anomaly flags | tenderer_count_flag |
| Aggregation rule | One tender record per OCID; count distinct OCIDs |
| Double-counting risk | Low - same as M-C01 |
| Interpretation caveat | Single-bidder procurement may reflect legitimate sole-source conditions or insufficient market competition. Source data does not distinguish these cases. |

---

### M-S01: Top Supplier Concentration (by Award Value Share)

| Field | Value |
|-------|-------|
| Metric ID | M-S01 |
| Metric name | Award value concentration - top N suppliers |
| Pillar | Pillar 3 - Supplier and Market Concentration |
| Business question | What share of total awarded value goes to the top 10 (or top 20) suppliers? |
| Analytical grain | Supplier (by supplier ID); award |
| Numerator | SUM of award values for the top N suppliers by award value |
| Denominator | SUM of award values across all eligible awards |
| Required fields | wards[].value.amount (non-null, non-zero); wards[].suppliers[].id (non-null, not INCOMPLETE) |
| Eligibility conditions | Award status = ctive; ward_value_flag IS NULL; monetary_flag IS NULL; supplier_id_flag IS NULL |
| Exclusion conditions | ward_value_flag = EXTREME (FCTA warehouse); monetary_flag = ZERO_VALUE; supplier_id_flag = INCOMPLETE |
| Anomaly flags | award_value_flag, monetary_flag, supplier_id_flag |
| Aggregation rule | Deduplicate awards by award ID across all releases per OCID. Then SUM per supplier ID. |
| Double-counting risk | HIGH - an award appearing in multiple releases for the same OCID would be double-counted. Mitigation: deduplicate at award ID level within each OCID before aggregating. |
| Interpretation caveat | Results should be caveated: 1,483 supplier IDs have multiple name variants; actual concentration may differ if name-variant groups represent the same entity. Incomplete IDs excluded but represent an unknown share of award value. |

---

### M-V01: Median Award Value

| Field | Value |
|-------|-------|
| Metric ID | M-V01 |
| Metric name | Median award value |
| Pillar | Pillar 4 - Contracting and Value Analysis |
| Business question | What is the typical monetary size of a federal procurement award? |
| Analytical grain | Award (deduplicated by award ID across releases per OCID) |
| Numerator | MEDIAN of wards[].value.amount across eligible awards |
| Denominator | N/A |
| Required fields | wards[].value.amount (non-null, > 0) |
| Eligibility conditions | Award status = ctive; ward_value_flag IS NULL; monetary_flag IS NULL |
| Exclusion conditions | ward_value_flag = EXTREME; monetary_flag = ZERO_VALUE |
| Anomaly flags | award_value_flag, monetary_flag |
| Aggregation rule | Deduplicate awards by award ID within OCID; then compute MEDIAN |
| Double-counting risk | HIGH - same as M-S01. Award ID deduplication is mandatory. |
| Interpretation caveat | The extreme FCTA warehouse award (NGN 1.004T) is excluded from the distribution benchmark. Reported separately in high-value procurement section. |

---

### M-E01: Median Tender Duration (Days)

| Field | Value |
|-------|-------|
| Metric ID | M-E01 |
| Metric name | Median tender open duration (days) |
| Pillar | Pillar 5 - Procurement Process Efficiency |
| Business question | How long are tenders typically open for bidding? |
| Analytical grain | OCID (one tender per process) |
| Numerator | MEDIAN of (tenderPeriod.endDate - tenderPeriod.startDate) in days |
| Denominator | N/A |
| Required fields | 	ender.tenderPeriod.startDate; 	ender.tenderPeriod.endDate; both non-null, date_quality_flag = VALID, endDate >= startDate |
| Eligibility conditions | Both dates non-null and VALID; computed duration >= 0 |
| Exclusion conditions | date_quality_flag IN (PLACEHOLDER, FUTURE, IMPOSSIBLE) for either date; negative computed duration |
| Anomaly flags | date_quality_flag |
| Aggregation rule | One tender record per OCID; compute date difference; then MEDIAN |
| Double-counting risk | Low - duration is a computed value from one pair of dates per process. |
| Interpretation caveat | Coverage is limited: tender start date is null in 47.7% of tender releases. The eligible population (~9,593 OCIDs) may not be representative of all procurement. |

---

### M-E02: Median Award Lag (Days from Tender Start to Award)

| Field | Value |
|-------|-------|
| Metric ID | M-E02 |
| Metric name | Median award lag (tender start to award date) |
| Pillar | Pillar 5 - Procurement Process Efficiency |
| Business question | How long does it typically take from opening a tender to making an award? |
| Analytical grain | OCID |
| Numerator | MEDIAN of (awards[].date - tender.tenderPeriod.startDate) in days |
| Denominator | N/A |
| Required fields | 	ender.tenderPeriod.startDate; wards[].date; both non-null and date_quality_flag = VALID; award date >= tender start date |
| Eligibility conditions | Both dates non-null and VALID; award date >= tender start date; OCID has exactly one definitive award record |
| Exclusion conditions | date_quality_flag IN (PLACEHOLDER, FUTURE, IMPOSSIBLE) for either date; negative computed lag |
| Anomaly flags | date_quality_flag |
| Aggregation rule | One tender and one award date per OCID (process-snapshot rule); compute lag; MEDIAN |
| Double-counting risk | Low if dates are correctly deduplicated per OCID |
| Interpretation caveat | Negative lag values (award before tender start) would indicate chronological impossibility; such records must be excluded. Coverage limited by date availability. |

---

### M-E03: Procurement Lifecycle Conversion Rate

| Field | Value |
|-------|-------|
| Metric ID | M-E03 |
| Metric name | Procurement lifecycle stage conversion rates |
| Pillar | Pillar 5 - Procurement Process Efficiency / Pillar 1 - Planning |
| Business question | What proportion of planned procurements progress to tender, award, and contract? |
| Analytical grain | OCID |
| Numerator | COUNT of OCIDs reaching each lifecycle stage |
| Denominator | COUNT of OCIDs at the preceding stage |
| Required fields | 
eleases[].ocid; 
eleases[].tag |
| Eligibility conditions | None beyond having an OCID and tag |
| Exclusion conditions | None - all OCIDs are eligible for this coverage metric |
| Anomaly flags | None required |
| Aggregation rule | Classify each OCID by the highest lifecycle stage present across all its releases. Then compute stage-to-stage conversion ratios. |
| Double-counting risk | None - each OCID counted once regardless of release count |
| Interpretation caveat | Conversion rates reflect what is reported in NOCOPO, not necessarily what occurred. Absent reporting does not prove absent procurement activity. |

---

### M-I01: Contract Implementation Reporting Coverage

| Field | Value |
|-------|-------|
| Metric ID | M-I01 |
| Metric name | Contract implementation reporting coverage |
| Pillar | Pillar 5 - Procurement Process Efficiency |
| Business question | What proportion of contracts have implementation (payment/milestone) records? |
| Analytical grain | Contract |
| Numerator | COUNT of contracts with a non-null implementation sub-object |
| Denominator | COUNT of all contract records |
| Required fields | contracts[].implementation (presence/absence) |
| Eligibility conditions | Release has a contracts[] array; contract record is present |
| Exclusion conditions | None |
| Anomaly flags | None |
| Aggregation rule | Count at contract level; aggregate to buyer level for entity comparisons |
| Double-counting risk | Low if contracts are deduplicated by contract ID across releases per OCID |
| Interpretation caveat | A contract with an implementation record indicates that payment/milestone data was submitted to NOCOPO, not that the contract was successfully implemented. Transaction dates are universally absent (DQ-11); implementation timing cannot be measured. |

---

## Section 4: Remaining Analytical Design Notes

### 4.1 Currency

All monetary values confirmed as NGN. No currency conversion required. This simplifies
cross-entity and cross-period monetary comparisons, but note that NGN inflation over
the dataset period (approximately 2010-2021) means nominal comparisons across years
should be treated carefully.

### 4.2 Procurement Method Classification

All tender records carry procurementMethod = open. The granular field is
procurementMethodDetails, which includes values such as: National Competitive
Bidding, Selective Tendering, Direct Procurement.
All segmentation by method should use procurementMethodDetails, not procurementMethod.

### 4.3 Lifecycle Stage Tagging

The 	ag field in each release identifies the lifecycle stage(s) present. The full
set of observed tag combinations is documented in docs/data_profiling_report.md Section 3.
The primary tag combinations relevant to analysis are:
- [planning] only: 89,869 releases
- [planning, tender, award, contract, implementation]: 14,894 releases (most complete)
- Other partial combinations: ~3,500 releases

### 4.4 Date Priority Hierarchy

For temporal analysis, use the following priority chain when selecting the best available
event date for a procurement process:

1. 	ender.tenderPeriod.startDate (for tender event date)
2. wards[].date (for award event date)
3. contracts[].dateSigned (for contract event date)
4. contracts[].period.startDate (for contract commencement)

Do not use 
eleases[].date for procurement event timing (it is the publication batch date).

---

*Document version: 1.0 - 2026-08-16. Approved by project owner.*
*No SQL has been written. No schema has been designed.*
*Next reference: docs/phase3_data_dictionary.md*
