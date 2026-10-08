# Dashboard Reconciliation Log
# Nigeria Public Procurement Intelligence

> **Phase 9 exit gate:** every figure shown on the dashboard reconciles with its source SQL view/query.
> **SQL values generated:** 2026-10-08 21:13 from `nocopo_db` (role `postgres`) by `python/validation/06_generate_reconciliation_log.py`  
> **Source query:** `dashboard/reconciliation_expected_values.sql`  
> **Measure definitions:** `dashboard/README.md` §6  
> **Figures:** 177

## How to use

1. Refresh the Power BI model (run `sql/04_transformations/04_refresh_snapshot.sql` first if staging or `core.dim_buyer` changed).
2. Clear every slicer, then set only the filter named in the **Slice** column.
3. Type the value the dashboard shows into **Dashboard value**, in the same format as **SQL value**.
4. **Match** is `yes` when counts, days and bands are identical, NGN amounts agree to the whole naira, and ratios and shares agree to the displayed precision. Anything else is `NO`: write the cause in **Notes** and do not publish the page until it is resolved.
5. Sign each row with your initials and the date. If the SQL value is stale (data refreshed), re-run the source query and update the row.

A mismatch is a defect in the Power BI model or in the measure, never in the SQL view: the views are validated by `04_run_validation_suite.py --phase 6`, `--phase 7`, `--phase 8` and `--phase 9`.

## Executive overview

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| EXE-01 | Procurement processes in scope | none | `[Processes (n)]` | 98,454 | 98,454 |  |  |  |  |
| EXE-02 | Planned budget, NGN | none | `[Planned Budget (NGN)]` | 93,279,493,391,521 | 96,802 |  |  |  |  |
| EXE-03 | Awarded value, NGN (M-V01) | none | `[Award Value (NGN)]` | 3,290,579,600,245 | 15,763 |  |  |  |  |
| EXE-04 | Median award value, NGN (M-V01) | none | `[Median Award Value (NGN)]` | 35,259,446 | 15,763 |  |  |  |  |
| EXE-05 | Single-bidder rate, primary (M-C02) | none | `[Single-Bidder Rate (primary)]` | 44.04% | 17,253 |  |  |  |  |
| EXE-06 | Median tenderers, primary (M-C01) | none | `[Median Tenderers (primary)]` | 2 | 17,253 |  |  |  |  |
| EXE-07 | Top-10 supplier share of value (M-S01) | none | `[Top N Supplier Share] with N = 10` | 29.00% | 13,537 |  |  |  |  |
| EXE-08 | M-S01 excluded value, share of eligible award value | none | `[M-S01 Excluded Value Share]` | 20.37% | 15,763 |  |  |  |  |
| EXE-09 | Median award-to-budget ratio | none | `[Median Award-to-Budget Ratio]` | 0.9298 | 15,574 |  |  |  |  |
| EXE-10 | Median tender open duration, days (M-E01) | none | `[Median Tender Duration (days)]` | 28 | 9,040 |  |  |  |  |
| EXE-11 | Median award lag, days (M-E02) | none | `[Median Award Lag (days)]` | 97 | 7,462 |  |  |  |  |
| EXE-12 | Implementation reporting coverage (M-I01) | none | `[Implementation Coverage Rate]` | 87.17% | 16,221 |  |  |  |  |
| EXE-13 | Processes that stop at planning stage (DQ-02 disclosure) | none | `[Planning-Only Share]` | 82.32% | 98,454 |  |  |  |  |

## Supplier concentration

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| SUP-01 | Eligible awards with a usable supplier ID | none | `[M-S01 Eligible Awards]` | 13,537 | 13,537 |  |  |  |  |
| SUP-02 | Distinct suppliers | none | `[Suppliers (n)]` | 9,800 | 13,537 |  |  |  |  |
| SUP-03 | Value attributed to suppliers, NGN | none | `[Supplier Value (NGN)]` | 2,620,191,366,881 | 13,537 |  |  |  |  |
| SUP-04 | Top-1 supplier share | none | `[Top N Supplier Share] with N = 1` | 8.03% | 13,537 |  |  |  |  |
| SUP-05 | Top-5 supplier share | none | `[Top N Supplier Share] with N = 5` | 21.46% | 13,537 |  |  |  |  |
| SUP-06 | Top-10 supplier share | none | `[Top N Supplier Share] with N = 10` | 29.00% | 13,537 |  |  |  |  |
| SUP-07 | Top-20 supplier share | none | `[Top N Supplier Share] with N = 20` | 37.50% | 13,537 |  |  |  |  |
| SUP-08 | Top-100 supplier share | none | `[Top N Supplier Share] with N = 100` | 59.45% | 13,537 |  |  |  |  |
| SUP-09 | Herfindahl index (0 to 10,000) | none | `[Supplier HHI]` | 139.4 | 13,537 |  |  |  |  |
| SUP-10 | Suppliers with exactly one award | none | `[Suppliers With One Award]` | 7,631 | 9,800 |  |  |  |  |
| SUP-11 | Disclosure: eligible awards excluded (no usable supplier ID) | none | `[M-S01 Excluded Awards]` | 2,226 | 15,763 |  |  |  |  |
| SUP-12 | Disclosure: excluded award value, NGN | none | `[M-S01 Excluded Value (NGN)]` | 670,388,233,365 | 15,763 |  |  |  |  |
| SUP-13 | Disclosure: excluded share of eligible award value | none | `[M-S01 Excluded Value Share]` | 20.37% | 15,763 |  |  |  |  |
| SUP-14 | Disclosure read from the DQ view: excluded awards (DQ-14) | none | `[M-S01 Excluded Awards (DQ view)]` | 2,226 | 15,763 |  |  |  |  |
| SUP-15 | Disclosure read from the DQ view: excluded value (DQ-14), NGN | none | `[M-S01 Excluded Value (DQ view)]` | 670,388,233,365 | 15,763 |  |  |  |  |
| SUP-16 | Top-1 supplier share within National Competitive Bidding | method = National Competitive Bidding | `[Top N Supplier Share] with N = 1` | 6.88% | 7,761 |  |  |  |  |
| SUP-17 | Top-1 supplier share within Emergency | method = Emergency | `[Top N Supplier Share] with N = 1` | 61.44% | 363 |  |  |  |  |
| SUP-18 | Herfindahl index within Emergency | method = Emergency | `[Supplier HHI]` | 4238.1 | 363 |  |  |  |  |

## Competition

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| COM-01 | Eligible tenders, primary (1-100 tenderers) | none | `[Competition n (primary)]` | 17,253 | 17,253 |  |  |  |  |
| COM-02 | Eligible tenders, sensitivity (adds 101-1,000) | none | `[Competition n (sensitivity)]` | 17,266 | 17,266 |  |  |  |  |
| COM-03 | Median tenderers, primary (M-C01) | none | `[Median Tenderers (primary)]` | 2 | 17,253 |  |  |  |  |
| COM-04 | Median tenderers, sensitivity | none | `[Median Tenderers (sensitivity)]` | 2 | 17,266 |  |  |  |  |
| COM-05 | Single-bidder rate, primary (M-C02) | none | `[Single-Bidder Rate (primary)]` | 44.04% | 17,253 |  |  |  |  |
| COM-06 | Single-bidder rate, sensitivity | none | `[Single-Bidder Rate (sensitivity)]` | 44.01% | 17,266 |  |  |  |  |
| COM-07 | Single-bidder rate, primary, Direct Procurement | method = Direct Procurement | `[Single-Bidder Rate (primary)]` | 89.50% | 1,095 |  |  |  |  |
| COM-08 | Single-bidder rate, primary, National Competitive Bidding | method = National Competitive Bidding | `[Single-Bidder Rate (primary)]` | 39.58% | 10,129 |  |  |  |  |
| COM-09 | Single-bidder rate, primary, tender status active | tender_status = active | `[Single-Bidder Rate (primary)]` | 46.20% | 6,585 |  |  |  |  |
| COM-10 | Median tenderers, primary, National Competitive Bidding | method = National Competitive Bidding | `[Median Tenderers (primary)]` | 3 | 10,129 |  |  |  |  |
| COM-B1 | Participation band 1 (1 tenderer): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 7,599 | 17,266 |  |  |  |  |
| COM-B2 | Participation band 2 (2 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 1,138 | 17,266 |  |  |  |  |
| COM-B3 | Participation band 3 (3-5 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 6,567 | 17,266 |  |  |  |  |
| COM-B4 | Participation band 4 (6-10 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 1,319 | 17,266 |  |  |  |  |
| COM-B5 | Participation band 5 (11-20 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 467 | 17,266 |  |  |  |  |
| COM-B6 | Participation band 6 (21-50 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 150 | 17,266 |  |  |  |  |
| COM-B7 | Participation band 7 (51-100 tenderers): tenders | population = primary | `[Tenders (n)] by [Participation Band]` | 13 | 17,266 |  |  |  |  |
| COM-B8 | Participation band 8 (101-1,000 (sensitivity only)): tenders | population = sensitivity only | `[Tenders (n)] by [Participation Band]` | 13 | 17,266 |  |  |  |  |

## Budget vs award

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| BVA-01 | Comparable OCIDs | none | `[Comparable OCIDs]` | 15,574 | 15,574 |  |  |  |  |
| BVA-02 | Total planned budget of comparable OCIDs, NGN | none | `[Budget of Comparable OCIDs (NGN)]` | 12,434,523,083,234 | 15,574 |  |  |  |  |
| BVA-03 | Total award value of comparable OCIDs, NGN | none | `[Award of Comparable OCIDs (NGN)]` | 3,091,515,320,328 | 15,574 |  |  |  |  |
| BVA-04 | Net difference (award minus budget), NGN | none | `[Net Variance (NGN)]` | -9,343,007,762,906 | 15,574 |  |  |  |  |
| BVA-05 | Aggregate award-to-budget ratio | none | `[Aggregate Award-to-Budget Ratio]` | 0.2486 | 15,574 |  |  |  |  |
| BVA-06 | Median award-to-budget ratio | none | `[Median Award-to-Budget Ratio]` | 0.9298 | 15,574 |  |  |  |  |
| BVA-07 | Share of OCIDs within 10% of budget (ratio 0.9 to 1.1) | none | `[Share Within 10% of Budget]` | 42.15% | 15,574 |  |  |  |  |
| BVA-08 | Aggregate ratio, National Competitive Bidding | method = National Competitive Bidding | `[Aggregate Award-to-Budget Ratio]` | 0.2039 | 9,159 |  |  |  |  |
| BVA-09 | Median ratio, Emergency | method = Emergency | `[Median Award-to-Budget Ratio]` | 0.2313 | 379 |  |  |  |  |
| BVA-10 | Net difference, Federal Ministry of Works & Housing HQ, NGN | buyer = NG-BPP-BPP-NOC-231001001 | `[Net Variance (NGN)]` | -5,559,885,717,409 | 1,678 |  |  |  |  |
| BVA-11 | OCIDs with a budget under NGN 100,000 (placeholder-like, kept) | none | `[OCIDs With Budget Under 100k]` | 16 | 15,574 |  |  |  |  |
| BVA-B1 | Ratio band 1 (below 0.5): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 5,300 | 15,574 |  |  |  |  |
| BVA-B2 | Ratio band 2 (0.5 to under 0.9): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 2,118 | 15,574 |  |  |  |  |
| BVA-B3 | Ratio band 3 (0.9 to 1.1): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 6,564 | 15,574 |  |  |  |  |
| BVA-B4 | Ratio band 4 (over 1.1 to 1.5): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 453 | 15,574 |  |  |  |  |
| BVA-B5 | Ratio band 5 (over 1.5 to 10): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 912 | 15,574 |  |  |  |  |
| BVA-B6 | Ratio band 6 (over 10): OCIDs | none | `[Comparable OCIDs] by [Ratio Band]` | 227 | 15,574 |  |  |  |  |

## Timing

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| TIM-01 | Eligible tenders, tender open duration (M-E01) | none | `[Tender Duration n]` | 9,040 | 9,040 |  |  |  |  |
| TIM-02 | Eligible OCIDs, award lag (M-E02) | none | `[Award Lag n]` | 7,462 | 7,462 |  |  |  |  |
| TIM-03 | Eligible contracts, signature lag | none | `[Signature Lag n]` | 12,006 | 12,006 |  |  |  |  |
| TIM-04 | Median tender open duration, days | none | `[Median Tender Duration (days)]` | 28 | 9,040 |  |  |  |  |
| TIM-05 | Median award lag, days | none | `[Median Award Lag (days)]` | 97 | 7,462 |  |  |  |  |
| TIM-06 | Median signature lag, days | none | `[Median Signature Lag (days)]` | 5 | 12,006 |  |  |  |  |
| TIM-07 | 90th percentile tender open duration, days | none | `[P90 Tender Duration (days)]` | 64 | 9,040 |  |  |  |  |
| TIM-08 | 90th percentile award lag, days | none | `[P90 Award Lag (days)]` | 267 | 7,462 |  |  |  |  |
| TIM-09 | 90th percentile signature lag, days | none | `[P90 Signature Lag (days)]` | 62 | 12,006 |  |  |  |  |
| TIM-10 | Coverage of M-E01 (eligible share of candidate tenders) | none | `[Coverage M-E01]` | 51.94% | 9,040 |  |  |  |  |
| TIM-11 | Coverage of M-E02 (eligible share of candidate OCIDs) | none | `[Coverage M-E02]` | 45.15% | 7,462 |  |  |  |  |
| TIM-12 | Coverage of signature lag (eligible share of candidate contracts) | none | `[Coverage Signature Lag]` | 74.02% | 12,006 |  |  |  |  |
| TIM-13 | Share of award lags over one year | none | `[Award Lag Over 1 Year Share]` | 3.94% | 7,462 |  |  |  |  |
| TIM-14 | Median award lag, Emergency, days | method = Emergency | `[Median Award Lag (days)]` | 9 | 278 |  |  |  |  |
| TIM-15 | Median award lag, National Competitive Bidding, days | method = National Competitive Bidding | `[Median Award Lag (days)]` | 120 | 4,856 |  |  |  |  |
| TIM-16 | Median tender open duration, tender start year 2020, days | Tender Start Year = 2020 | `[Median Tender Duration (days)]` | 18 | 1,459 |  |  |  |  |
| TIM-17 | Median tender open duration, tender start year 2021, days | Tender Start Year = 2021 | `[Median Tender Duration (days)]` | 42 | 1,578 |  |  |  |  |
| TIM-D1-1 | Tender open duration, band 1 (up to 7 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 1,105 | 9,040 |  |  |  |  |
| TIM-D1-2 | Tender open duration, band 2 (8-30 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 3,745 | 9,040 |  |  |  |  |
| TIM-D1-3 | Tender open duration, band 3 (31-90 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 3,655 | 9,040 |  |  |  |  |
| TIM-D1-4 | Tender open duration, band 4 (91-180 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 367 | 9,040 |  |  |  |  |
| TIM-D1-5 | Tender open duration, band 5 (181-365 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 102 | 9,040 |  |  |  |  |
| TIM-D1-6 | Tender open duration, band 6 (over 1 year): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 66 | 9,040 |  |  |  |  |
| TIM-D2-1 | Award lag, band 1 (up to 7 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 257 | 7,462 |  |  |  |  |
| TIM-D2-2 | Award lag, band 2 (8-30 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 1,196 | 7,462 |  |  |  |  |
| TIM-D2-3 | Award lag, band 3 (31-90 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 1,934 | 7,462 |  |  |  |  |
| TIM-D2-4 | Award lag, band 4 (91-180 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 2,659 | 7,462 |  |  |  |  |
| TIM-D2-5 | Award lag, band 5 (181-365 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 1,122 | 7,462 |  |  |  |  |
| TIM-D2-6 | Award lag, band 6 (over 1 year): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 294 | 7,462 |  |  |  |  |
| TIM-D3-1 | Signature lag, band 1 (up to 7 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 6,854 | 12,006 |  |  |  |  |
| TIM-D3-2 | Signature lag, band 2 (8-30 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 2,427 | 12,006 |  |  |  |  |
| TIM-D3-3 | Signature lag, band 3 (31-90 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 2,233 | 12,006 |  |  |  |  |
| TIM-D3-4 | Signature lag, band 4 (91-180 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 249 | 12,006 |  |  |  |  |
| TIM-D3-5 | Signature lag, band 5 (181-365 days): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 87 | 12,006 |  |  |  |  |
| TIM-D3-6 | Signature lag, band 6 (over 1 year): processes | none | `[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]` | 156 | 12,006 |  |  |  |  |

## Entity benchmark

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| ENT-01 | Procuring entities (complete buyer IDs) | none | `[Entities (n)]` | 665 | 665 |  |  |  |  |
| ENT-02 | Processes across entities | none | `[Entity Processes]` | 98,428 | 665 |  |  |  |  |
| ENT-03 | Planned budget across entities, NGN | none | `[Entity Planned Budget (NGN)]` | 93,279,493,391,521 | 665 |  |  |  |  |
| ENT-04 | Awarded value across entities, NGN | none | `[Entity Award Value (NGN)]` | 3,289,424,600,245 | 665 |  |  |  |  |
| ENT-05 | Largest entity share of awarded value | none | `[Top N Entity Share] with N = 1` | 40.59% | 665 |  |  |  |  |
| ENT-06 | Top-10 entities share of awarded value | none | `[Top N Entity Share] with N = 10` | 76.04% | 665 |  |  |  |  |
| ENT-07 | Top-100 entities share of awarded value | none | `[Top N Entity Share] with N = 100` | 97.61% | 665 |  |  |  |  |
| ENT-08 | Median of entity single-bidder rates (entities with at least 30 primary tenders) | Min competition n = 30 | `[Median Entity Single-Bidder Rate]` | 41.67% | 103 |  |  |  |  |
| ENT-09 | Median of entity top-supplier shares (entities with at least 10 awards) | Min award n = 10 | `[Median Entity Top-Supplier Share]` | 22.21% | 173 |  |  |  |  |
| ENT-10 | Median of entity implementation coverage (entities with at least 20 contracts) | Min contract n = 20 | `[Median Entity Implementation Coverage]` | 99.07% | 123 |  |  |  |  |
| ENT-11 | Works & Housing HQ: single-bidder rate | buyer = NG-BPP-BPP-NOC-231001001 | `[Entity Single-Bidder Rate]` | 3.67% | 1,635 |  |  |  |  |
| ENT-12 | Works & Housing HQ: top-supplier share | buyer = NG-BPP-BPP-NOC-231001001 | `[Entity Top-Supplier Share]` | 11.13% | 1,682 |  |  |  |  |
| ENT-13 | Works & Housing HQ: implementation coverage | buyer = NG-BPP-BPP-NOC-231001001 | `[Entity Implementation Coverage]` | 21.59% | 1,677 |  |  |  |  |
| ENT-14 | Works & Housing HQ: tender reach rate | buyer = NG-BPP-BPP-NOC-231001001 | `[Entity Tender Reach Rate]` | 36.84% | 4,626 |  |  |  |  |
| ENT-15 | Works & Housing HQ: median award value, NGN | buyer = NG-BPP-BPP-NOC-231001001 | `[Entity Median Award Value (NGN)]` | 60,693,640 | 1,682 |  |  |  |  |

## Implementation & lifecycle

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| IMP-01 | Contracts in scope (M-I01) | none | `[Contracts (n)]` | 16,221 | 16,221 |  |  |  |  |
| IMP-02 | Contracts with implementation data | none | `[Contracts With Implementation Data]` | 14,140 | 16,221 |  |  |  |  |
| IMP-03 | Implementation reporting coverage rate (M-I01) | none | `[Implementation Coverage Rate]` | 87.17% | 16,221 |  |  |  |  |
| IMP-04 | Coverage rate, contract status pending | contract_status = pending | `[Implementation Coverage Rate]` | 74.38% | 121 |  |  |  |  |
| IMP-05 | Coverage rate, Works & Housing HQ | buyer = NG-BPP-BPP-NOC-231001001 | `[Implementation Coverage Rate]` | 21.59% | 1,677 |  |  |  |  |
| IMP-C2 | Lifecycle: conversion from stage 1 to stage 2 | Stage = 2 | `[Stage Conversion Rate]` | 17.68% | 98,454 |  |  |  |  |
| IMP-C3 | Lifecycle: conversion from stage 2 to stage 3 | Stage = 3 | `[Stage Conversion Rate]` | 94.96% | 17,405 |  |  |  |  |
| IMP-C4 | Lifecycle: conversion from stage 3 to stage 4 | Stage = 4 | `[Stage Conversion Rate]` | 98.15% | 16,527 |  |  |  |  |
| IMP-C5 | Lifecycle: conversion from stage 4 to stage 5 | Stage = 5 | `[Stage Conversion Rate]` | 87.23% | 16,221 |  |  |  |  |
| IMP-S1 | Lifecycle: OCIDs reaching stage 1 (planning) or beyond | Stage = 1 | `[OCIDs Reaching Stage]` | 98,454 | 98,454 |  |  |  |  |
| IMP-S2 | Lifecycle: OCIDs reaching stage 2 (tender) or beyond | Stage = 2 | `[OCIDs Reaching Stage]` | 17,405 | 98,454 |  |  |  |  |
| IMP-S3 | Lifecycle: OCIDs reaching stage 3 (award) or beyond | Stage = 3 | `[OCIDs Reaching Stage]` | 16,527 | 98,454 |  |  |  |  |
| IMP-S4 | Lifecycle: OCIDs reaching stage 4 (contract) or beyond | Stage = 4 | `[OCIDs Reaching Stage]` | 16,221 | 98,454 |  |  |  |  |
| IMP-S5 | Lifecycle: OCIDs reaching stage 5 (implementation) or beyond | Stage = 5 | `[OCIDs Reaching Stage]` | 14,149 | 98,454 |  |  |  |  |
| IMP-T1 | Implementation data type 1 (transactions and milestones): contracts | none | `[Contracts (n)] by [Implementation Data Type]` | 12,796 | 16,221 |  |  |  |  |
| IMP-T2 | Implementation data type 2 (milestones only): contracts | none | `[Contracts (n)] by [Implementation Data Type]` | 1,344 | 16,221 |  |  |  |  |
| IMP-T3 | Implementation data type 3 (transactions only): contracts | none | `[Contracts (n)] by [Implementation Data Type]` | 0 | 16,221 |  |  |  |  |
| IMP-T4 | Implementation data type 4 (no implementation data): contracts | none | `[Contracts (n)] by [Implementation Data Type]` | 2,081 | 16,221 |  |  |  |  |

## Data quality & coverage

| ID | Figure | Slice | DAX measure | SQL value | Eligible n | Dashboard value | Match | Checked by / date | Notes |
|---|---|---|---|---|---|---|---|---|---|
| DQ-C-ENTITY | Candidate population: ENTITY | none | `MetricPopulation[candidate_count]` | 666 | 666 |  |  |  |  |
| DQ-C-M-C01-M-C02 | Candidate population: M-C01 / M-C02 | none | `MetricPopulation[candidate_count]` | 17,405 | 17,405 |  |  |  |  |
| DQ-C-M-C01-sensitivity | Candidate population: M-C01 (sensitivity) | none | `MetricPopulation[candidate_count]` | 17,405 | 17,405 |  |  |  |  |
| DQ-C-M-E01 | Candidate population: M-E01 | none | `MetricPopulation[candidate_count]` | 17,405 | 17,405 |  |  |  |  |
| DQ-C-M-E02 | Candidate population: M-E02 | none | `MetricPopulation[candidate_count]` | 16,527 | 16,527 |  |  |  |  |
| DQ-C-M-E03 | Candidate population: M-E03 | none | `MetricPopulation[candidate_count]` | 98,454 | 98,454 |  |  |  |  |
| DQ-C-M-I01 | Candidate population: M-I01 | none | `MetricPopulation[candidate_count]` | 16,221 | 16,221 |  |  |  |  |
| DQ-C-M-P01 | Candidate population: M-P01 | none | `MetricPopulation[candidate_count]` | 97,353 | 97,353 |  |  |  |  |
| DQ-C-M-S01 | Candidate population: M-S01 | none | `MetricPopulation[candidate_count]` | 15,763 | 15,763 |  |  |  |  |
| DQ-C-M-V01 | Candidate population: M-V01 | none | `MetricPopulation[candidate_count]` | 16,527 | 16,527 |  |  |  |  |
| DQ-C-P4-BvA | Candidate population: P4-BvA | none | `MetricPopulation[candidate_count]` | 15,763 | 15,763 |  |  |  |  |
| DQ-C-P5-SIG | Candidate population: P5-SIG | none | `MetricPopulation[candidate_count]` | 16,221 | 16,221 |  |  |  |  |
| DQ-E-ENTITY | Eligible population: ENTITY | none | `MetricPopulation[eligible_count]` | 665 | 665 |  |  |  |  |
| DQ-E-M-C01-M-C02 | Eligible population: M-C01 / M-C02 | none | `MetricPopulation[eligible_count]` | 17,253 | 17,253 |  |  |  |  |
| DQ-E-M-C01-sensitivity | Eligible population: M-C01 (sensitivity) | none | `MetricPopulation[eligible_count]` | 17,266 | 17,266 |  |  |  |  |
| DQ-E-M-E01 | Eligible population: M-E01 | none | `MetricPopulation[eligible_count]` | 9,040 | 9,040 |  |  |  |  |
| DQ-E-M-E02 | Eligible population: M-E02 | none | `MetricPopulation[eligible_count]` | 7,462 | 7,462 |  |  |  |  |
| DQ-E-M-E03 | Eligible population: M-E03 | none | `MetricPopulation[eligible_count]` | 98,454 | 98,454 |  |  |  |  |
| DQ-E-M-I01 | Eligible population: M-I01 | none | `MetricPopulation[eligible_count]` | 16,221 | 16,221 |  |  |  |  |
| DQ-E-M-P01 | Eligible population: M-P01 | none | `MetricPopulation[eligible_count]` | 96,802 | 96,802 |  |  |  |  |
| DQ-E-M-S01 | Eligible population: M-S01 | none | `MetricPopulation[eligible_count]` | 13,537 | 13,537 |  |  |  |  |
| DQ-E-M-V01 | Eligible population: M-V01 | none | `MetricPopulation[eligible_count]` | 15,763 | 15,763 |  |  |  |  |
| DQ-E-P4-BvA | Eligible population: P4-BvA | none | `MetricPopulation[eligible_count]` | 15,574 | 15,574 |  |  |  |  |
| DQ-E-P5-SIG | Eligible population: P5-SIG | none | `MetricPopulation[eligible_count]` | 12,006 | 12,006 |  |  |  |  |
| DQ-P-ENTITY | Eligible share of candidates: ENTITY | none | `[Eligible Share]` | 99.85% | 665 |  |  |  |  |
| DQ-P-M-C01-M-C02 | Eligible share of candidates: M-C01 / M-C02 | none | `[Eligible Share]` | 99.13% | 17,253 |  |  |  |  |
| DQ-P-M-C01-sensitivity | Eligible share of candidates: M-C01 (sensitivity) | none | `[Eligible Share]` | 99.20% | 17,266 |  |  |  |  |
| DQ-P-M-E01 | Eligible share of candidates: M-E01 | none | `[Eligible Share]` | 51.94% | 9,040 |  |  |  |  |
| DQ-P-M-E02 | Eligible share of candidates: M-E02 | none | `[Eligible Share]` | 45.15% | 7,462 |  |  |  |  |
| DQ-P-M-E03 | Eligible share of candidates: M-E03 | none | `[Eligible Share]` | 100.00% | 98,454 |  |  |  |  |
| DQ-P-M-I01 | Eligible share of candidates: M-I01 | none | `[Eligible Share]` | 100.00% | 16,221 |  |  |  |  |
| DQ-P-M-P01 | Eligible share of candidates: M-P01 | none | `[Eligible Share]` | 99.43% | 96,802 |  |  |  |  |
| DQ-P-M-S01 | Eligible share of candidates: M-S01 | none | `[Eligible Share]` | 85.88% | 13,537 |  |  |  |  |
| DQ-P-M-V01 | Eligible share of candidates: M-V01 | none | `[Eligible Share]` | 95.38% | 15,763 |  |  |  |  |
| DQ-P-P4-BvA | Eligible share of candidates: P4-BvA | none | `[Eligible Share]` | 98.80% | 15,574 |  |  |  |  |
| DQ-P-P5-SIG | Eligible share of candidates: P5-SIG | none | `[Eligible Share]` | 74.02% | 12,006 |  |  |  |  |
| DQ-X1 | M-P01 extreme budgets (DQ-06): lines excluded | metric = M-P01, issue = DQ-06 | `DQImpact[records_with_issue]` | 32 | 97,353 |  |  |  |  |
| DQ-X2 | M-P01 extreme budgets (DQ-06): value excluded, NGN | metric = M-P01, issue = DQ-06 | `DQImpact[affected_value_ngn]` | 96,441,897,756,392 | 97,353 |  |  |  |  |
| DQ-X3 | M-V01 extreme award (DQ-07): awards excluded | metric = M-V01, issue = DQ-07 | `DQImpact[records_with_issue]` | 1 | 16,527 |  |  |  |  |
| DQ-X4 | M-V01 portal test entity (DQ-20): awards removed before the candidate population | metric = M-V01, issue = DQ-20 | `DQImpact[records_with_issue]` | 188 | 16,527 |  |  |  |  |
| DQ-X5 | M-E02 chronology conflicts (award before tender start): excluded | metric = M-E02, issue = DATE-ORDER | `DQImpact[records_with_issue]` | 135 | 16,527 |  |  |  |  |
| DQ-X6 | M-E01 records excluded for any reason (candidate minus eligible) | metric = M-E01, issue = ALL | `DQImpact[records_with_issue]` | 8,365 | 17,405 |  |  |  |  |
| DQ-X7 | M-S01 awards with several name variants (DQ-13, disclosed, kept) | metric = M-S01, issue = DQ-13 | `DQImpact[records_with_issue]` | 4,177 | 13,537 |  |  |  |  |

---

*Generated by `python/validation/06_generate_reconciliation_log.py`. Raw dataset, stg.* and core.* not modified.*
