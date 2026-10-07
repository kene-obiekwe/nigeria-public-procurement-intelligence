# Phase 6 — Gate B Validation Results

> **Runner:** `python/validation/04_run_validation_suite.py`  
> **Run date:** 2026-10-07 18:02:37  
> **Database:** `nocopo_db` on localhost:5433 (PostgreSQL 17.4)  
> **Gate B result:** **PASSED**. Stage 1 passed; 102 / 102 GATE checks passed; 17 INFO measurements.

Interpretation and decisions: `docs/phase6_core_model/phase6_core_model.md`.

## Stage 1 — Raw → staging (independent JSON traversal)

`python/ingest/02_reconcile_staging.py`: 64 checks, 0 failed. (✓). Detail: `docs/phase5_staging/phase5_staging_results.md`.

## Stage 2 — SQL validation suite (`sql/03_data_quality/`)

### Key uniqueness — `01_key_uniqueness.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| UQ-01 | stg.releases.release_id | GATE | 0 | 0 | ✓ |
| UQ-02 | stg.releases.release_seq | GATE | 0 | 0 | ✓ |
| UQ-03 | stg.planning.release_id | GATE | 0 | 0 | ✓ |
| UQ-04 | stg.tender.release_id | GATE | 0 | 0 | ✓ |
| UQ-05 | stg.tender.tender_id (alternate key) | GATE | 0 | 0 | ✓ |
| UQ-06 | stg.awards.award_id | GATE | 0 | 0 | ✓ |
| UQ-07 | stg.award_suppliers (award_id, supplier_seq) | GATE | 0 | 0 | ✓ |
| UQ-08 | stg.contracts.contract_id | GATE | 0 | 0 | ✓ |
| UQ-09 | stg.contracts.award_id (one contract per award) | GATE | 0 | 0 | ✓ |
| UQ-10 | stg.transactions.transaction_pk | GATE | 0 | 0 | ✓ |
| UQ-11 | stg.milestones.milestone_pk | GATE | 0 | 0 | ✓ |
| UQ-12 | stg.parties.party_pk | GATE | 0 | 0 | ✓ |
| UQ-13 | stg.parties (release_id, party_id) | GATE | 0 | 0 | ✓ |
| UQ-14 | core.dim_buyer.buyer_id | GATE | 0 | 0 | ✓ |
| UQ-15 | core.dim_supplier.supplier_id | GATE | 0 | 0 | ✓ |
| UQ-16 | core.vw_process_snapshot.ocid | GATE | 0 | 0 | ✓ |
| UQ-17 | core.vw_budget_lines (ocid, budget_project_id) | GATE | 0 | 0 | ✓ |
| UQ-18 | budget_project_id never spans >1 OCID | GATE | 0 | 0 | ✓ |

### Null rates — `02_null_rates.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| NL-01 | stg.releases.ocid NULL | GATE | 0 | 0 | ✓ |
| NL-02 | stg.releases.buyer_id NULL | GATE | 0 | 0 | ✓ |
| NL-03 | stg.tender.tender_id NULL | GATE | 0 | 0 | ✓ |
| NL-04 | stg.contracts.award_id NULL | GATE | 0 | 0 | ✓ |
| NL-05 | stg.award_suppliers.supplier_id NULL | GATE | 0 | 0 | ✓ |
| NL-06 | stg.parties.party_id NULL | GATE | 0 | 0 | ✓ |
| NL-07 | stg.tender.number_of_tenderers NULL | GATE | 0 | 0 | ✓ |
| NL-08 | stg.awards.award_value_amount NULL | GATE | 0 | 0 | ✓ |
| NL-09 | stg.planning.budget_amount NULL (1,649 releases without a budget; Phase 2: 106,628 present) | GATE | 1,649 | 1,649 | ✓ |
| NL-10 | stg.tender.tender_start_date NULL (Phase 2: 8,786) | GATE | 8,786 | 8,786 | ✓ |
| NL-11 | stg.tender.tender_end_date NULL (Phase 2: 8,786) | GATE | 8,786 | 8,786 | ✓ |
| NL-12 | stg.awards.award_date NULL (Phase 2: 2,630) | GATE | 2,630 | 2,630 | ✓ |
| NL-13 | stg.contracts.date_signed NULL (17,043 - 14,386 present) | GATE | 2,657 | 2,657 | ✓ |
| NL-14 | stg.releases.buyer_name NULL | GATE | 26 | 26 | ✓ |
| NL-15 | stg.releases party_flag = NO_PARTIES (DQ-18) | GATE | 20 | 20 | ✓ |
| NL-16 | stg.awards.status NULL | INFO |  | 2 | info |
| NL-17 | core.dim_buyer.buyer_name NULL (bare NG-BPP- buyer has no name) | GATE | 1 | 1 | ✓ |
| NL-18 | core.dim_supplier.supplier_name NULL | INFO |  | 0 | info |

### Referential integrity — `03_referential_integrity.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| RI-01 | stg.planning -> stg.releases | GATE | 0 | 0 | ✓ |
| RI-02 | stg.tender -> stg.releases | GATE | 0 | 0 | ✓ |
| RI-03 | stg.awards -> stg.releases | GATE | 0 | 0 | ✓ |
| RI-04 | stg.award_suppliers -> stg.awards | GATE | 0 | 0 | ✓ |
| RI-05 | stg.contracts -> stg.releases | GATE | 0 | 0 | ✓ |
| RI-06 | stg.contracts -> stg.awards | GATE | 0 | 0 | ✓ |
| RI-07 | contract and its award in the same release | GATE | 0 | 0 | ✓ |
| RI-08 | stg.transactions -> stg.contracts | GATE | 0 | 0 | ✓ |
| RI-09 | stg.milestones -> stg.contracts | GATE | 0 | 0 | ✓ |
| RI-10 | stg.parties -> stg.releases | GATE | 0 | 0 | ✓ |
| RI-11 | stg.releases.buyer_id -> core.dim_buyer | GATE | 0 | 0 | ✓ |
| RI-12 | stg.award_suppliers.supplier_id -> core.dim_supplier | GATE | 0 | 0 | ✓ |
| RI-13 | supplier-role stg.parties -> core.dim_supplier | GATE | 0 | 0 | ✓ |
| RI-14 | snapshot.buyer_id -> core.dim_buyer | GATE | 0 | 0 | ✓ |
| RI-15 | budget_lines.buyer_id -> core.dim_buyer | GATE | 0 | 0 | ✓ |
| RI-16 | snapshot award has its contract when one exists in the award release | GATE | 0 | 0 | ✓ |
| RI-17 | snapshot tender_release_id / award_release_id belong to the OCID | GATE | 0 | 0 | ✓ |

### Release reconciliation — `04_release_reconciliation.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| RL-01 | Snapshot rows = distinct OCIDs in staging | GATE | 98,866 | 98,866 | ✓ |
| RL-02 | Multi-release OCIDs (Phase 4.1: 6,280) | GATE | 6,280 | 6,280 | ✓ |
| RL-03 | Budget lines (Phase 4.1: 97,749) | GATE | 97,749 | 97,749 | ✓ |
| RL-04 | OCIDs flagged MULTI_PROJECT (Phase 4.1 / C-06: 192) | GATE | 192 | 192 | ✓ |
| RL-05 | Budget-line total excl. EXTREME, NGN bn (Phase 4.1 R3: 93,827.8) | GATE | 93827.8 | 93827.8 | ✓ |
| RL-06 | Budget-line total: view = independent NOT EXISTS formulation (NGN) | GATE | 190269651068904.9300 | 190269651068904.9300 | ✓ |
| RL-07 | Snapshot OCIDs with a tender = distinct OCIDs having a tender | GATE | 17,623 | 17,623 | ✓ |
| RL-08 | Snapshot OCIDs with an award = distinct OCIDs having an award | GATE | 16,715 | 16,715 | ✓ |
| RL-09 | Snapshot award total = independent NOT EXISTS formulation (NGN) | GATE | 4383632505475.1200 | 4383632505475.1200 | ✓ |
| RL-10 | Award value across ALL releases (would double count), NGN | INFO |  | 4719623321230.6000 | info |
| RL-11 | Award value in snapshot (one award per OCID), NGN | INFO |  | 4383632505475.1200 | info |
| RL-12 | Budget across ALL releases incl. repeats (would double count), NGN | INFO |  | 206066299972578.4661 | info |
| RL-13 | Multi-release OCIDs where text order of release_id picks a different latest release (Phase 4.1: 1,508) | GATE | 1,508 | 1,508 | ✓ |

### Monetary & date validity — `05_monetary_and_date_validity.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| MD-01 | Negative monetary values (all 5 money columns) | GATE | 0 | 0 | ✓ |
| MD-02 | Non-NGN currency codes (all 5 money columns) | GATE | 0 | 0 | ✓ |
| MD-03 | Amount present but currency missing | GATE | 0 | 0 | ✓ |
| MD-04 | DQ-06 budget EXTREME (>= NGN 1T) | GATE | 32 | 32 | ✓ |
| MD-05 | DQ-07 award EXTREME (>= NGN 1T) | GATE | 1 | 1 | ✓ |
| MD-06 | DQ-16 budget ZERO_VALUE | GATE | 561 | 561 | ✓ |
| MD-07 | DQ-16 tender value ZERO_VALUE | GATE | 1,259 | 1,259 | ✓ |
| MD-08 | DQ-16 award ZERO_VALUE | GATE | 268 | 268 | ✓ |
| MD-09 | DQ-05 tenderer count ANOMALOUS (> 1,000) | GATE | 65 | 65 | ✓ |
| MD-10 | DQ-04 tenderer count ELEVATED (101-1,000), per C-07 | GATE | 14 | 14 | ✓ |
| MD-11 | Date flag / date NULL mismatch (10 date columns) | GATE | 0 | 0 | ✓ |
| MD-12 | DQ-08 PLACEHOLDER tender start (Phase 2: 24) | GATE | 24 | 24 | ✓ |
| MD-13 | DQ-08 PLACEHOLDER award date (Phase 2: 119) | GATE | 119 | 119 | ✓ |
| MD-14 | DQ-08 PLACEHOLDER contract signed (Phase 2: 77) | GATE | 77 | 77 | ✓ |
| MD-15 | DQ-09 IMPOSSIBLE award date (year 2922) | GATE | 1 | 1 | ✓ |
| MD-16 | DQ-08 PLACEHOLDER milestone due date (Phase 4.1: 38) | GATE | 38 | 38 | ✓ |
| MD-17 | Tender end before tender start (both VALID) | INFO |  | 0 | info |
| MD-18 | Award date before tender start, same release (both VALID) | INFO |  | 149 | info |
| MD-19 | Contract signed before award date (both VALID) | INFO |  | 792 | info |
| MD-20 | Contract period end before period start (both VALID) | INFO |  | 0 | info |

### Entity consistency — `06_entity_consistency.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| EN-01 | core.dim_buyer rows = distinct staging buyer_id (666 complete + bare NG-BPP-) | GATE | 667 | 667 | ✓ |
| EN-02 | Complete buyer IDs = distinct buyer-role party IDs (Phase 2: 666) | GATE | 666 | 666 | ✓ |
| EN-03 | Releases with bare NG-BPP- buyer ID (flagged INCOMPLETE) | GATE | 26 | 26 | ✓ |
| EN-04 | Buyer IDs with >1 release-level name | GATE | 0 | 0 | ✓ |
| EN-05 | core.dim_supplier rows = distinct supplier IDs (parties UNION awards) | GATE | 10,325 | 10,325 | ✓ |
| EN-06 | Supplier-role party IDs (Phase 2: 10,296) | GATE | 10,296 | 10,296 | ✓ |
| EN-07 | Supplier IDs seen only in awards[].suppliers[] | INFO |  | 29 | info |
| EN-08 | Awards with no supplier-role party in their release | INFO |  | 1,137 | info |
| EN-09 | DQ-13: supplier IDs with >1 name (Phase 2: 1,483) | GATE | 1,483 | 1,483 | ✓ |
| EN-10 | DQ-14: supplier names with >1 ID (Phase 2: 571) | GATE | 571 | 571 | ✓ |
| EN-11 | DQ-14: supplier-role parties with bare NG-BPP- ID | GATE | 1,390 | 1,390 | ✓ |
| EN-12 | Award-supplier rows carrying bare NG-BPP- ID (excluded from M-S01) | INFO |  | 2,452 | info |
| EN-13 | Max distinct suppliers on one award | GATE | 1 | 1 | ✓ |
| EN-14 | Award supplier ID = supplier party ID in the same release (where both exist): mismatches | GATE | 0 | 0 | ✓ |

### Layer reconciliation — `07_layer_reconciliation.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| LR-01 | raw releases = stg.releases | GATE | 108,277 | 108,277 | ✓ |
| LR-02 | raw planning = stg.planning | GATE | 108,277 | 108,277 | ✓ |
| LR-03 | raw tenders = stg.tender | GATE | 18,408 | 18,408 | ✓ |
| LR-04 | raw awards = stg.awards | GATE | 17,417 | 17,417 | ✓ |
| LR-05 | raw award suppliers = stg.award_suppliers | GATE | 17,441 | 17,441 | ✓ |
| LR-06 | raw contracts = stg.contracts | GATE | 17,043 | 17,043 | ✓ |
| LR-07 | raw transactions = stg.transactions | GATE | 13,617 | 13,617 | ✓ |
| LR-08 | raw milestones = stg.milestones | GATE | 42,854 | 42,854 | ✓ |
| LR-09 | raw parties = stg.parties | GATE | 124,530 | 124,530 | ✓ |
| LR-10 | raw OCIDs = core.vw_process_snapshot | GATE | 98,866 | 98,866 | ✓ |
| LR-11 | staging distinct buyer IDs = core.dim_buyer | GATE | 667 | 667 | ✓ |
| LR-12 | staging releases = sum of dim_buyer.release_count | GATE | 108,277 | 108,277 | ✓ |
| LR-13 | staging releases = sum of snapshot release_count | GATE | 108,277 | 108,277 | ✓ |
| LR-14 | staging distinct (ocid, budget line) = core.vw_budget_lines | GATE | 97,749 | 97,749 | ✓ |

### Observations — `08_observations.sql`

| ID | Check | Severity | Expected | Actual | Result |
|---|---|---|---|---|---|
| OB-01 | O-1: tender-award pairs (same release) with tender value = award value | INFO |  | 17417 of 17417 | info |
| OB-02 | O-1: contracts with contract value = award value | INFO |  | 17043 of 17043 | info |
| OB-03 | O-1: tenders without an award whose tender value is 0 | INFO |  | 991 of 991 | info |
| OB-04 | O-3: repeated supplier entries on one award (deduplicate in M-S01, Phase 7) | INFO |  | 24 | info |
| OB-05 | O-3: awards carrying repeated supplier entries | INFO |  | 6 | info |

---

*Generated by `python/validation/04_run_validation_suite.py`. Raw dataset not modified.*
