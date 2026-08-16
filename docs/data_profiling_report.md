# NOCOPO Dataset — Data Profiling Report

> **Project:** Nigeria Public Procurement Intelligence  
> **Script:** `python/profiling/01_structural_profiler.py`  
> **Run date:** 2026-08-15 16:48:54  
> **Status:** Phase 2 — Initial Structural & Data-Quality Audit  
> **Raw data is READ-ONLY. This report contains observations only.**

---

## 1. Source Inventory

| Field | Value |
|-------|-------|
| Source file | `NOCOPO dataset/all07010.json` |
| File size | 219,816,927 bytes (209.6 MB) |
| OCDS package URI | `http://nocopo.bpp.gov.ng/ocdsjson.ashx?ocid=all` |
| OCDS version | `1.1` |
| Published date | `2021-05-03T22:44:00Z` |
| Publisher | `{'name': 'The Bureau of Public Procurement', 'scheme': 'NG-BPP', 'uid': 'BPP-01'}` |
| License | `http://nocopo.bpp.gov.ng/license` |
| Publication policy | `http://nocopo.bpp.gov.ng/policy` |
| Acquisition / run date | 2026-08-15 16:48:54 |

> **Observed:** Single-file OCDS 1.1 release package. Published 2021-05-03.
> The file name `all07010.json` suggests a full bulk export (all records) rather than a filtered slice.

## 2. Release Counts & OCID Analysis

| Metric | Count |
|--------|-------|
| Total releases | 108,277 |
| Unique OCIDs | 98,866 |
| Null/missing OCIDs | 0 |
| OCIDs appearing more than once (multi-release) | 6,280 |
| Maximum releases for a single OCID | 74 |
| Unique release IDs (`id` field) | 108,277 |

### Key finding: OCID repetition

- 98,866 unique OCIDs exist across 108,277 releases.
- 6,280 OCIDs appear in more than one release — these represent procurement
  processes with multiple lifecycle stages or updates within the dataset.
- **This is expected OCDS behaviour**, not automatic duplication.
  A single procurement process (`ocid`) can have multiple releases tagged
  `planning`, `tender`, `award`, `contract`, or `implementation`.
- **Decision required (Phase 3):** Establish the release/version modelling strategy
  before aggregating monetary values to avoid double-counting.

## 3. Tag / Lifecycle Stage Analysis

Tags indicate which lifecycle stage(s) are represented in each release.

| Tag combination | Count | % of releases |
|----------------|-------|---------------|
| `planning` | 89,869 | 83.0% |
| `award, contract, implementation, planning, tender` | 14,894 | 13.8% |
| `award, contract, planning, tender` | 2,149 | 2.0% |
| `planning, tender` | 991 | 0.9% |
| `award, planning, tender` | 374 | 0.3% |

### Key findings

- **89,869 releases** (83.0%) carry only the `planning` tag
  — these are planning-stage records with no tender, award or contract data.
- **14,894 releases** carry all five tags
  — these represent apparently complete procurement lifecycle records.
- **2,149 releases** have planning through contract but no `implementation` tag.
- The `implementation` tag appears only as part of multi-tag releases;
  no standalone `implementation` release was observed.

## 4. Lifecycle Section Presence

Presence means the field is non-null and non-empty at the release level.

| Section | Releases present | % |
|---------|-----------------|---|
| `planning` | 108,277 | 100.0% |
| `tender` | 18,408 | 17.0% |
| `awards_non_empty` | 17,417 | 16.1% |
| `contracts_non_empty` | 17,043 | 15.7% |
| `implementation_in_tag` | 14,894 | 13.8% |
| `parties_non_empty` | 108,257 | 100.0% |
| `buyer` | 108,277 | 100.0% |

### Key findings

- `planning` is present in **all 108,277** releases.
- `tender`, `awards`, `contracts` are present in ~15–17% of releases.
- `implementation` tag appears in 14,894 releases,
  but the `implementation` **section** (as a separate top-level key) appears to be absent
  or embedded differently. This requires deeper field-level inspection.
- 20 releases have no `parties` array — may be data gaps.

## 5. Monetary Data Analysis

### 5.1 Budget Amounts (from `planning.budget.amount`)

- Releases with `planning.budget` present: 106,628 (98.5%)
- Releases with numeric budget amount: 106,628 (98.5%)
- Budget amount nulls/missing: 0

| Statistic | Value (NGN) |
|-----------|-------------|
| Count with numeric value | 106,628 |
| Minimum | 0.00 |
| Maximum | 6,500,000,000,000.00 |
| Mean | 1,932,572,119.64 |
| Zero values | 561 |
| Negative values | 0 |

- Budget currencies observed: `NGN`: 106,628

### 5.2 Tender Values (from `tender.value.amount`)

- Releases with tender section: 18,408
- Tender value amounts present: 18,408 (100.0% of tender releases)

| Statistic | Value (NGN) |
|-----------|-------------|
| Count with numeric value | 18,408 |
| Minimum | 0.00 |
| Maximum | 1,004,166,666,735.23 |
| Mean | 256,389,793.63 |
| Zero values | 1,259 |
| Negative values | 0 |

### 5.3 Award Values (from `awards[].value.amount`)

- Total award objects: 17,417
- Award values present (numeric): 17,417 (100.0% of awards)
- Award value null/missing: 0
- Releases with multiple awards: 0

| Statistic | Value (NGN) |
|-----------|-------------|
| Count with numeric value | 17,417 |
| Minimum | 0.00 |
| Maximum | 1,004,166,666,735.23 |
| Mean | 270,977,971.02 |
| Zero values | 268 |
| Negative values | 0 |

#### Award status distribution

| Status | Count |
|--------|-------|
| `active` | 16,845 |
| `cancelled` | 386 |
| `pending` | 159 |
| `unsuccessful` | 25 |

## 6. Date Analysis

### 6.1 Tender Period Start Date

| Metric | Value |
|--------|-------|
| Total date fields inspected | 18,408 |
| Null/missing | 8,786 (47.7%) |
| Suspicious (2001-01-01, 1970-01-01 etc.) | 24 |
| Unparseable format | 0 |
| Successfully parsed | 9,622 |
| Earliest date | 2001-01-01 |
| Latest date | 2029-11-04 |

### 6.2 Tender Period End Date

| Metric | Value |
|--------|-------|
| Total date fields inspected | 18,408 |
| Null/missing | 8,786 (47.7%) |
| Suspicious (2001-01-01, 1970-01-01 etc.) | 0 |
| Unparseable format | 0 |
| Successfully parsed | 9,622 |
| Earliest date | 2010-08-15 |
| Latest date | 2029-11-10 |

### 6.3 Award Date

| Metric | Value |
|--------|-------|
| Total date fields inspected | 17,417 |
| Null/missing | 2,630 (15.1%) |
| Suspicious (2001-01-01, 1970-01-01 etc.) | 119 |
| Unparseable format | 0 |
| Successfully parsed | 14,787 |
| Earliest date | 2001-01-01 |
| Latest date | 2922-08-26 |

### 6.4 Suspicious date observation

- Dates of `2001-01-01T00:00:00Z` were observed in milestone `dueDate` and `dateMet` fields
  in the first few sampled records.
- This pattern is a known OCDS/system data-entry artefact (placeholder/default date).
- **Preliminary hypothesis:** `2001-01-01` is a system placeholder for 'date not recorded'.
- **Confirmed action needed:** Count how many tender/award/contract dates use this placeholder.
  These must be excluded from any procurement-timing or cycle-duration calculations.

## 7. Entity & Party Analysis

### 7.1 Party roles (total across all party objects in all releases)

| Role | Count |
|------|-------|
| `buyer` | 108,250 |
| `payer` | 108,250 |
| `procuringEntity` | 108,250 |
| `supplier` | 16,280 |
| `tenderer` | 16,280 |
| `payee` | 16,280 |

### 7.2 Supplier identifiers and names

- Total supplier party objects: 16,280
- Supplier IDs null/missing: 0 (0.0%)
- Unique supplier IDs (non-null): 10,296
- Unique supplier names (non-null): 12,717

> **Observation:** More unique supplier names than supplier IDs may indicate
> name variations for the same entity, or multiple ID-less suppliers sharing a
> common name. This must be investigated before supplier concentration analysis.

### 7.3 Procuring entity identifiers and names

- Total procuring-entity/buyer party objects: 108,250
- Procuring entity IDs null/missing: 0 (0.0%)
- Unique procuring-entity IDs (non-null): 666
- Unique procuring-entity names (non-null): 680

## 8. Procurement Method Distribution

Based on `tender.procurementMethod` field (where tender section present):

| Method | Count |
|--------|-------|
| `open` | 18,408 |

Based on `tender.procurementMethodDetails` (top 15):

| Method Details | Count |
|---------------|-------|
| `National Competitive Bidding` | 10,842 |
| `Selective Tendering` | 4,035 |
| `Direct Procurement` | 1,129 |
| `Request for quotation` | 783 |
| `National Shopping` | 618 |
| `Emergency` | 409 |
| `Repeat Procurement` | 288 |
| `International Competitive Bidding` | 85 |
| `Sole Source` | 49 |
| `Direct Labour` | 20 |

## 9. Competition / Tenderer Count Analysis

- Releases with tender section: 18,408
- `numberOfTenderers` null/missing: 0 (0.0%)
- `numberOfTenderers` present: 18,408
- Minimum tenderers: 1
- Maximum tenderers: 90865
- Mean tenderers: 28.3
- Zero-tenderer records: 0

> **Critical note:** Missing `numberOfTenderers` does NOT mean zero tenderers.
> It means the field was not recorded. These must not be imputed as 0.

## 10. Suppliers per Award

| Suppliers per award | Count of awards |
|---------------------|----------------|
| 1 | 17,411 |
| 5 | 6 |

## 11. Repeated-OCID Tag Patterns (Multi-release Processes)

Tag combinations observed within the set of repeated (multi-release) OCIDs:

| Tag combination | Occurrence count (releases) |
|----------------|----------------------------|
| `planning` | 14,123 |
| `award, contract, implementation, planning, tender` | 1,137 |
| `planning, tender` | 183 |
| `award, contract, planning, tender` | 146 |
| `award, planning, tender` | 102 |

> **Interpretation required (Phase 3):** These patterns suggest that some procurement
> processes are represented by multiple releases at different stages. The release/version
> strategy must be decided before aggregating values for repeated OCIDs.

## 12. Contract Section Analysis

- Total contract objects: 17,043

| Contract status | Count |
|----------------|-------|
| `active` | 16,450 |
| `cancelled` | 357 |
| `pending` | 123 |
| `terminated` | 113 |

## 13. Summary of Data-Quality Issues for Phase 3 Decision Log

> **⚠️ CORRECTION (2026-08-16):** Row 1 of this table originally stated "9,411 OCIDs appear in >1 release".
> This was a **reporting error** — the figure `9,411` was carried forward from an earlier script version
> and was not updated after the script was corrected and re-run.
> The **confirmed correct figures**, verified by `python/profiling/02_targeted_validation.py`, are:
> - **6,280 OCIDs** appear in more than one release (repeated/multi-release processes)
> - **9,411 excess releases** exist (i.e., sum of (count − 1) across all repeated OCIDs)
> The original text is preserved below for traceability. See `docs/targeted_validation_report.md` Section 1.

| # | Issue | Scope | Preliminary treatment |
|---|-------|-------|----------------------|
| 1 | **OCID repetition** — ~~9,411 OCIDs~~ → **6,280 OCIDs** appear in >1 release (9,411 *excess releases*) | 6,280 OCIDs / 9,411 excess releases | UNRESOLVED — release strategy required (Phase 3) |
| 2 | **Planning-only releases** — 89,869 releases have no tender/award/contract | 83.0% of releases | RETAIN — valid planning records; exclude from metrics requiring later stages |
| 3 | **Placeholder dates** (`2001-01-01`) — confirmed in tender start (24), award date (119), contract signed (77) | 220+ date fields | FLAG — exclude from timing metrics |
| 4 | **`numberOfTenderers`** — confirmed present in all 18,408 tender releases (0 missing); extreme outlier of 90,865 confirmed in Federal Min. of Works records | 65 extreme records | FLAG extreme values; exclude from distribution statistics |
| 5 | **Award values** — confirmed present in all 17,417 awards (0 null); 268 zeros require investigation | 268 zero-value awards | Requires investigation |
| 6 | **Supplier entity resolution** — 1,483 IDs map to >1 name; 571 names map to >1 ID | Across all suppliers | UNRESOLVED — entity-resolution strategy required |
| 7 | **`implementation` section** — confirmed nested inside `contracts[].implementation`; transactions have no `date` field; all 13,617 transactions have `value` field | 14,884 contracts | FLAG — frame as reporting-coverage metric, not payment analysis |
| 8 | **Zero monetary values** — 561 budget zeros, 268 award zeros, 1,259 tender value zeros | To be investigated | Requires investigation — may be legitimate or placeholder |
| 9 | **Releases with no `parties`** — 20 releases | 20 releases | FLAG — investigate; may affect buyer/supplier joins |
| 10 | **Single published date** — all releases share `2021-05-03` as `date` | 108,277 releases | CONFIRMED: use internal event dates for temporal analysis |
| 11 | **Extreme budget values** — 32 records ≥ ₦1 trillion; max ₦6.5T (TCN), others from NPHCDA (Hajj vaccines) and Fed. Min. Works | 32 records | FLAG — retain; exclude from summary statistics without special handling |
| 12 | **Extreme award/tender value** — ₦1.004 trillion (FCTA, warehouse construction, M/S Turaki Trading) | 1 record | FLAG — retain; investigate plausibility before inclusion in aggregations |
| 13 | **Extreme future / erroneous dates** — award date year 2922; tender/award dates up to 2029–2033 | Multiple records | FLAG — exclude from timing metrics; retain in dataset |


## 14. Open Questions Requiring Further Investigation

1. **Release date semantics:** All sampled releases share `date=2021-05-03T22:44:00Z`.
   Are there internal date fields (e.g., `tender.tenderPeriod.startDate`,
   `awards[].date`) that carry the actual procurement event dates?

2. **`implementation` section structure:** The `implementation` tag is present in
   14,894 releases, but the `implementation` key at release level was not detected
   as a top-level section in this scan. It may be nested inside `contracts[]`.
   A targeted field scan of contracts is required.

3. **Release/version strategy:** Which release(s) should represent a procurement
   process for aggregation? Latest-release snapshot? Lifecycle union? This is
   the single most important decision before schema design.

4. **OCID structure semantics:** The OCID prefix `ocds-gyl66f-` followed by what
   appears to be an entity/ministry code. Does this encode a meaningful procuring-entity
   identifier? Investigation warranted.

5. **Zero-value monetary fields:** Are any zero budget/award amounts legitimate
   (e.g., in-kind, framework without value) or all system placeholders?

6. **Supplier identifier scheme:** All observed IDs use scheme `NG-BPP`. Is this
   a stable, reliable identifier for entity resolution? Null rate must be measured.

---

## 15. Implications for Relational Modelling and Analytics

| Analytical pillar | Impact of findings |
|---|---|
| **Supplier concentration** | Requires entity-resolution decision; repeated-OCID strategy affects award-value aggregation |
| **Competition analysis** | 83% planning-only releases have no tender data; tenderer count missingness is substantial |
| **Budget-to-award variance** | Budget present in most releases; award in only 16% — comparison population will be small |
| **Procurement timing** | Placeholder dates must be identified and excluded; release date may not equal event date |
| **Entity benchmarking** | Procuring-entity IDs appear reliable; name normalization needed |
| **Implementation/reporting** | Implementation section structure unclear; coverage likely to be very limited |

---

*Report generated by `python/profiling/01_structural_profiler.py`.*  
*Raw dataset was not modified. Run date: 2026-08-15 16:48:54.*