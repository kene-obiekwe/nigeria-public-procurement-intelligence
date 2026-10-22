# Web Dashboard Reconciliation Results
# Nigeria Public Procurement Intelligence

> **Generated:** 2026-10-22 12:57 by `python/web/check_web_data.py` (role `nocopo_bi`, read-only)  
> **Data:** `web/data/` exported 2026-10-22T10:48:41Z by role `nocopo_bi` from `nocopo_db` (PostgreSQL 17.4); source SHA-256 `6151466…bc90c`  
> **Result:** PASS: manifest verified; reconciliation 177/177 PASS; DQ-21 sensitivity 277/277 cells PASS; wording 0 finding(s)

The figures below are recomputed from the JSON files alone, by Python functions that mirror the DAX measures (`dashboard/README.md` §5), and compared with the live SQL. The site's JavaScript is checked separately by `web/check.html` (section 4).

## 1. Manifest

Rows: as written to the manifest, recounted from the JSON, and counted live in the source view(s). Aggregated files (lifecycle, budget, contracts) count the source rows they summarise.

| File | Manifest rows | JSON rows | Live view rows | KB | gzip KB | SHA-256 and size | Result |
|---|---|---|---|---|---|---|---|
| `dims.json` | 676 | 676 | 676 | 78.6 | 13.8 | match | PASS |
| `lifecycle.json` | 98,454 | 98,454 | 98,454 | 10.4 | 3.2 | match | PASS |
| `budget.json` | 96,802 | 96,802 | 96,802 | 13.0 | 6.3 | match | PASS |
| `suppliers.json` | 9,800 | 9,800 |  | 502.9 | 126.7 | match | PASS |
| `competition.json` | 17,266 | 17,266 | 17,266 | 233.6 | 14.9 | match | PASS |
| `awards.json` | 15,763 | 15,763 | 15,763 | 360.4 | 107.8 | match | PASS |
| `budget_award.json` | 15,574 | 15,574 | 15,574 | 557.1 | 136.3 | match | PASS |
| `tender_duration.json` | 9,040 | 9,040 | 9,040 | 120.9 | 8.5 | match | PASS |
| `award_lag.json` | 7,462 | 7,462 | 7,462 | 103.7 | 9.5 | match | PASS |
| `signature_lag.json` | 12,006 | 12,006 | 12,006 | 73.4 | 12.9 | match | PASS |
| `contracts.json` | 16,221 | 16,221 | 16,221 | 5.9 | 1.4 | match | PASS |
| `entities.json` | 665 | 665 | 665 | 55.6 | 16.8 | match | PASS |
| `registers.json` | 59 | 59 | 59 | 14.2 | 3.0 | match | PASS |
| `expected.json` | 177 | 177 | 177 | 40.2 | 6.6 | match | PASS |
| **Total** | | | | **2,170.0** | **467.8** | | |

## 2. Reconciliation: 177/177 PASS

Source: `dashboard/reconciliation_expected_values.sql`, re-run live; `expected.json` equals the live values. Tolerance: counts, days and bands identical; NGN to the whole naira; ratios and shares to four decimals; index to one decimal. IMP-T3 (transactions only) is 0 in SQL; the web shows 0.

| ID | Figure | Slice | SQL value | Web value | Result |
|---|---|---|---|---|---|
| EXE-01 | Procurement processes in scope | none | 98,454 | 98,454 | PASS |
| EXE-02 | Planned budget, NGN | none | 93,279,493,391,521 | 93,279,493,391,521 | PASS |
| EXE-03 | Awarded value, NGN (M-V01) | none | 3,290,579,600,245 | 3,290,579,600,245 | PASS |
| EXE-04 | Median award value, NGN (M-V01) | none | 35,259,446 | 35,259,446 | PASS |
| EXE-05 | Single-bidder rate, primary (M-C02) | none | 44.04% | 44.04% | PASS |
| EXE-06 | Median tenderers, primary (M-C01) | none | 2 | 2 | PASS |
| EXE-07 | Top-10 supplier share of value (M-S01) | none | 29.00% | 29.00% | PASS |
| EXE-08 | M-S01 excluded value, share of eligible award value | none | 20.37% | 20.37% | PASS |
| EXE-09 | Median award-to-budget ratio | none | 0.9298 | 0.9298 | PASS |
| EXE-10 | Median tender open duration, days (M-E01) | none | 28 | 28 | PASS |
| EXE-11 | Median award lag, days (M-E02) | none | 97 | 97 | PASS |
| EXE-12 | Implementation reporting coverage (M-I01) | none | 87.17% | 87.17% | PASS |
| EXE-13 | Processes that stop at planning stage (DQ-02 disclosure) | none | 82.32% | 82.32% | PASS |
| SUP-01 | Eligible awards with a usable supplier ID | none | 13,537 | 13,537 | PASS |
| SUP-02 | Distinct suppliers | none | 9,800 | 9,800 | PASS |
| SUP-03 | Value attributed to suppliers, NGN | none | 2,620,191,366,881 | 2,620,191,366,881 | PASS |
| SUP-04 | Top-1 supplier share | none | 8.03% | 8.03% | PASS |
| SUP-05 | Top-5 supplier share | none | 21.46% | 21.46% | PASS |
| SUP-06 | Top-10 supplier share | none | 29.00% | 29.00% | PASS |
| SUP-07 | Top-20 supplier share | none | 37.50% | 37.50% | PASS |
| SUP-08 | Top-100 supplier share | none | 59.45% | 59.45% | PASS |
| SUP-09 | Herfindahl index (0 to 10,000) | none | 139.4 | 139.4 | PASS |
| SUP-10 | Suppliers with exactly one award | none | 7,631 | 7,631 | PASS |
| SUP-11 | Disclosure: eligible awards excluded (no usable supplier ID) | none | 2,226 | 2,226 | PASS |
| SUP-12 | Disclosure: excluded award value, NGN | none | 670,388,233,365 | 670,388,233,365 | PASS |
| SUP-13 | Disclosure: excluded share of eligible award value | none | 20.37% | 20.37% | PASS |
| SUP-14 | Disclosure read from the DQ view: excluded awards (DQ-14) | none | 2,226 | 2,226 | PASS |
| SUP-15 | Disclosure read from the DQ view: excluded value (DQ-14), NGN | none | 670,388,233,365 | 670,388,233,365 | PASS |
| SUP-16 | Top-1 supplier share within National Competitive Bidding | method = National Competitive Bidding | 6.88% | 6.88% | PASS |
| SUP-17 | Top-1 supplier share within Emergency | method = Emergency | 61.44% | 61.44% | PASS |
| SUP-18 | Herfindahl index within Emergency | method = Emergency | 4238.1 | 4238.1 | PASS |
| COM-01 | Eligible tenders, primary (1-100 tenderers) | none | 17,253 | 17,253 | PASS |
| COM-02 | Eligible tenders, sensitivity (adds 101-1,000) | none | 17,266 | 17,266 | PASS |
| COM-03 | Median tenderers, primary (M-C01) | none | 2 | 2 | PASS |
| COM-04 | Median tenderers, sensitivity | none | 2 | 2 | PASS |
| COM-05 | Single-bidder rate, primary (M-C02) | none | 44.04% | 44.04% | PASS |
| COM-06 | Single-bidder rate, sensitivity | none | 44.01% | 44.01% | PASS |
| COM-07 | Single-bidder rate, primary, Direct Procurement | method = Direct Procurement | 89.50% | 89.50% | PASS |
| COM-08 | Single-bidder rate, primary, National Competitive Bidding | method = National Competitive Bidding | 39.58% | 39.58% | PASS |
| COM-09 | Single-bidder rate, primary, tender status active | tender_status = active | 46.20% | 46.20% | PASS |
| COM-10 | Median tenderers, primary, National Competitive Bidding | method = National Competitive Bidding | 3 | 3 | PASS |
| COM-B1 | Participation band 1 (1 tenderer): tenders | population = primary | 7,599 | 7,599 | PASS |
| COM-B2 | Participation band 2 (2 tenderers): tenders | population = primary | 1,138 | 1,138 | PASS |
| COM-B3 | Participation band 3 (3-5 tenderers): tenders | population = primary | 6,567 | 6,567 | PASS |
| COM-B4 | Participation band 4 (6-10 tenderers): tenders | population = primary | 1,319 | 1,319 | PASS |
| COM-B5 | Participation band 5 (11-20 tenderers): tenders | population = primary | 467 | 467 | PASS |
| COM-B6 | Participation band 6 (21-50 tenderers): tenders | population = primary | 150 | 150 | PASS |
| COM-B7 | Participation band 7 (51-100 tenderers): tenders | population = primary | 13 | 13 | PASS |
| COM-B8 | Participation band 8 (101-1,000 (sensitivity only)): tenders | population = sensitivity only | 13 | 13 | PASS |
| BVA-01 | Comparable OCIDs | none | 15,574 | 15,574 | PASS |
| BVA-02 | Total planned budget of comparable OCIDs, NGN | none | 12,434,523,083,234 | 12,434,523,083,234 | PASS |
| BVA-03 | Total award value of comparable OCIDs, NGN | none | 3,091,515,320,328 | 3,091,515,320,328 | PASS |
| BVA-04 | Net difference (award minus budget), NGN | none | -9,343,007,762,906 | -9,343,007,762,906 | PASS |
| BVA-05 | Aggregate award-to-budget ratio | none | 0.2486 | 0.2486 | PASS |
| BVA-06 | Median award-to-budget ratio | none | 0.9298 | 0.9298 | PASS |
| BVA-07 | Share of OCIDs within 10% of budget (ratio 0.9 to 1.1) | none | 42.15% | 42.15% | PASS |
| BVA-08 | Aggregate ratio, National Competitive Bidding | method = National Competitive Bidding | 0.2039 | 0.2039 | PASS |
| BVA-09 | Median ratio, Emergency | method = Emergency | 0.2313 | 0.2313 | PASS |
| BVA-10 | Net difference, Federal Ministry of Works & Housing HQ, NGN | buyer = NG-BPP-BPP-NOC-231001001 | -5,559,885,717,409 | -5,559,885,717,409 | PASS |
| BVA-11 | OCIDs with a budget under NGN 100,000 (placeholder-like, kept) | none | 16 | 16 | PASS |
| BVA-B1 | Ratio band 1 (below 0.5): OCIDs | none | 5,300 | 5,300 | PASS |
| BVA-B2 | Ratio band 2 (0.5 to under 0.9): OCIDs | none | 2,118 | 2,118 | PASS |
| BVA-B3 | Ratio band 3 (0.9 to 1.1): OCIDs | none | 6,564 | 6,564 | PASS |
| BVA-B4 | Ratio band 4 (over 1.1 to 1.5): OCIDs | none | 453 | 453 | PASS |
| BVA-B5 | Ratio band 5 (over 1.5 to 10): OCIDs | none | 912 | 912 | PASS |
| BVA-B6 | Ratio band 6 (over 10): OCIDs | none | 227 | 227 | PASS |
| TIM-01 | Eligible tenders, tender open duration (M-E01) | none | 9,040 | 9,040 | PASS |
| TIM-02 | Eligible OCIDs, award lag (M-E02) | none | 7,462 | 7,462 | PASS |
| TIM-03 | Eligible contracts, signature lag | none | 12,006 | 12,006 | PASS |
| TIM-04 | Median tender open duration, days | none | 28 | 28 | PASS |
| TIM-05 | Median award lag, days | none | 97 | 97 | PASS |
| TIM-06 | Median signature lag, days | none | 5 | 5 | PASS |
| TIM-07 | 90th percentile tender open duration, days | none | 64 | 64 | PASS |
| TIM-08 | 90th percentile award lag, days | none | 267 | 267 | PASS |
| TIM-09 | 90th percentile signature lag, days | none | 62 | 62 | PASS |
| TIM-10 | Coverage of M-E01 (eligible share of candidate tenders) | none | 51.94% | 51.94% | PASS |
| TIM-11 | Coverage of M-E02 (eligible share of candidate OCIDs) | none | 45.15% | 45.15% | PASS |
| TIM-12 | Coverage of signature lag (eligible share of candidate contracts) | none | 74.02% | 74.02% | PASS |
| TIM-13 | Share of award lags over one year | none | 3.94% | 3.94% | PASS |
| TIM-14 | Median award lag, Emergency, days | method = Emergency | 9 | 9 | PASS |
| TIM-15 | Median award lag, National Competitive Bidding, days | method = National Competitive Bidding | 120 | 120 | PASS |
| TIM-16 | Median tender open duration, tender start year 2020, days | Tender Start Year = 2020 | 18 | 18 | PASS |
| TIM-17 | Median tender open duration, tender start year 2021, days | Tender Start Year = 2021 | 42 | 42 | PASS |
| TIM-D1-1 | Tender open duration, band 1 (up to 7 days): processes | none | 1,105 | 1,105 | PASS |
| TIM-D1-2 | Tender open duration, band 2 (8-30 days): processes | none | 3,745 | 3,745 | PASS |
| TIM-D1-3 | Tender open duration, band 3 (31-90 days): processes | none | 3,655 | 3,655 | PASS |
| TIM-D1-4 | Tender open duration, band 4 (91-180 days): processes | none | 367 | 367 | PASS |
| TIM-D1-5 | Tender open duration, band 5 (181-365 days): processes | none | 102 | 102 | PASS |
| TIM-D1-6 | Tender open duration, band 6 (over 1 year): processes | none | 66 | 66 | PASS |
| TIM-D2-1 | Award lag, band 1 (up to 7 days): processes | none | 257 | 257 | PASS |
| TIM-D2-2 | Award lag, band 2 (8-30 days): processes | none | 1,196 | 1,196 | PASS |
| TIM-D2-3 | Award lag, band 3 (31-90 days): processes | none | 1,934 | 1,934 | PASS |
| TIM-D2-4 | Award lag, band 4 (91-180 days): processes | none | 2,659 | 2,659 | PASS |
| TIM-D2-5 | Award lag, band 5 (181-365 days): processes | none | 1,122 | 1,122 | PASS |
| TIM-D2-6 | Award lag, band 6 (over 1 year): processes | none | 294 | 294 | PASS |
| TIM-D3-1 | Signature lag, band 1 (up to 7 days): processes | none | 6,854 | 6,854 | PASS |
| TIM-D3-2 | Signature lag, band 2 (8-30 days): processes | none | 2,427 | 2,427 | PASS |
| TIM-D3-3 | Signature lag, band 3 (31-90 days): processes | none | 2,233 | 2,233 | PASS |
| TIM-D3-4 | Signature lag, band 4 (91-180 days): processes | none | 249 | 249 | PASS |
| TIM-D3-5 | Signature lag, band 5 (181-365 days): processes | none | 87 | 87 | PASS |
| TIM-D3-6 | Signature lag, band 6 (over 1 year): processes | none | 156 | 156 | PASS |
| ENT-01 | Procuring entities (complete buyer IDs) | none | 665 | 665 | PASS |
| ENT-02 | Processes across entities | none | 98,428 | 98,428 | PASS |
| ENT-03 | Planned budget across entities, NGN | none | 93,279,493,391,521 | 93,279,493,391,521 | PASS |
| ENT-04 | Awarded value across entities, NGN | none | 3,289,424,600,245 | 3,289,424,600,245 | PASS |
| ENT-05 | Largest entity share of awarded value | none | 40.59% | 40.59% | PASS |
| ENT-06 | Top-10 entities share of awarded value | none | 76.04% | 76.04% | PASS |
| ENT-07 | Top-100 entities share of awarded value | none | 97.61% | 97.61% | PASS |
| ENT-08 | Median of entity single-bidder rates (entities with at least 30 primary tenders) | Min competition n = 30 | 41.67% | 41.67% | PASS |
| ENT-09 | Median of entity top-supplier shares (entities with at least 10 awards) | Min award n = 10 | 22.21% | 22.21% | PASS |
| ENT-10 | Median of entity implementation coverage (entities with at least 20 contracts) | Min contract n = 20 | 99.07% | 99.07% | PASS |
| ENT-11 | Works & Housing HQ: single-bidder rate | buyer = NG-BPP-BPP-NOC-231001001 | 3.67% | 3.67% | PASS |
| ENT-12 | Works & Housing HQ: top-supplier share | buyer = NG-BPP-BPP-NOC-231001001 | 11.13% | 11.13% | PASS |
| ENT-13 | Works & Housing HQ: implementation coverage | buyer = NG-BPP-BPP-NOC-231001001 | 21.59% | 21.59% | PASS |
| ENT-14 | Works & Housing HQ: tender reach rate | buyer = NG-BPP-BPP-NOC-231001001 | 36.84% | 36.84% | PASS |
| ENT-15 | Works & Housing HQ: median award value, NGN | buyer = NG-BPP-BPP-NOC-231001001 | 60,693,640 | 60,693,640 | PASS |
| IMP-01 | Contracts in scope (M-I01) | none | 16,221 | 16,221 | PASS |
| IMP-02 | Contracts with implementation data | none | 14,140 | 14,140 | PASS |
| IMP-03 | Implementation reporting coverage rate (M-I01) | none | 87.17% | 87.17% | PASS |
| IMP-04 | Coverage rate, contract status pending | contract_status = pending | 74.38% | 74.38% | PASS |
| IMP-05 | Coverage rate, Works & Housing HQ | buyer = NG-BPP-BPP-NOC-231001001 | 21.59% | 21.59% | PASS |
| IMP-C2 | Lifecycle: conversion from stage 1 to stage 2 | Stage = 2 | 17.68% | 17.68% | PASS |
| IMP-C3 | Lifecycle: conversion from stage 2 to stage 3 | Stage = 3 | 94.96% | 94.96% | PASS |
| IMP-C4 | Lifecycle: conversion from stage 3 to stage 4 | Stage = 4 | 98.15% | 98.15% | PASS |
| IMP-C5 | Lifecycle: conversion from stage 4 to stage 5 | Stage = 5 | 87.23% | 87.23% | PASS |
| IMP-S1 | Lifecycle: OCIDs reaching stage 1 (planning) or beyond | Stage = 1 | 98,454 | 98,454 | PASS |
| IMP-S2 | Lifecycle: OCIDs reaching stage 2 (tender) or beyond | Stage = 2 | 17,405 | 17,405 | PASS |
| IMP-S3 | Lifecycle: OCIDs reaching stage 3 (award) or beyond | Stage = 3 | 16,527 | 16,527 | PASS |
| IMP-S4 | Lifecycle: OCIDs reaching stage 4 (contract) or beyond | Stage = 4 | 16,221 | 16,221 | PASS |
| IMP-S5 | Lifecycle: OCIDs reaching stage 5 (implementation) or beyond | Stage = 5 | 14,149 | 14,149 | PASS |
| IMP-T1 | Implementation data type 1 (transactions and milestones): contracts | none | 12,796 | 12,796 | PASS |
| IMP-T2 | Implementation data type 2 (milestones only): contracts | none | 1,344 | 1,344 | PASS |
| IMP-T3 | Implementation data type 3 (transactions only): contracts | none | 0 | 0 | PASS |
| IMP-T4 | Implementation data type 4 (no implementation data): contracts | none | 2,081 | 2,081 | PASS |
| DQ-C-ENTITY | Candidate population: ENTITY | none | 666 | 666 | PASS |
| DQ-C-M-C01-M-C02 | Candidate population: M-C01 / M-C02 | none | 17,405 | 17,405 | PASS |
| DQ-C-M-C01-sensitivity | Candidate population: M-C01 (sensitivity) | none | 17,405 | 17,405 | PASS |
| DQ-C-M-E01 | Candidate population: M-E01 | none | 17,405 | 17,405 | PASS |
| DQ-C-M-E02 | Candidate population: M-E02 | none | 16,527 | 16,527 | PASS |
| DQ-C-M-E03 | Candidate population: M-E03 | none | 98,454 | 98,454 | PASS |
| DQ-C-M-I01 | Candidate population: M-I01 | none | 16,221 | 16,221 | PASS |
| DQ-C-M-P01 | Candidate population: M-P01 | none | 97,353 | 97,353 | PASS |
| DQ-C-M-S01 | Candidate population: M-S01 | none | 15,763 | 15,763 | PASS |
| DQ-C-M-V01 | Candidate population: M-V01 | none | 16,527 | 16,527 | PASS |
| DQ-C-P4-BvA | Candidate population: P4-BvA | none | 15,763 | 15,763 | PASS |
| DQ-C-P5-SIG | Candidate population: P5-SIG | none | 16,221 | 16,221 | PASS |
| DQ-E-ENTITY | Eligible population: ENTITY | none | 665 | 665 | PASS |
| DQ-E-M-C01-M-C02 | Eligible population: M-C01 / M-C02 | none | 17,253 | 17,253 | PASS |
| DQ-E-M-C01-sensitivity | Eligible population: M-C01 (sensitivity) | none | 17,266 | 17,266 | PASS |
| DQ-E-M-E01 | Eligible population: M-E01 | none | 9,040 | 9,040 | PASS |
| DQ-E-M-E02 | Eligible population: M-E02 | none | 7,462 | 7,462 | PASS |
| DQ-E-M-E03 | Eligible population: M-E03 | none | 98,454 | 98,454 | PASS |
| DQ-E-M-I01 | Eligible population: M-I01 | none | 16,221 | 16,221 | PASS |
| DQ-E-M-P01 | Eligible population: M-P01 | none | 96,802 | 96,802 | PASS |
| DQ-E-M-S01 | Eligible population: M-S01 | none | 13,537 | 13,537 | PASS |
| DQ-E-M-V01 | Eligible population: M-V01 | none | 15,763 | 15,763 | PASS |
| DQ-E-P4-BvA | Eligible population: P4-BvA | none | 15,574 | 15,574 | PASS |
| DQ-E-P5-SIG | Eligible population: P5-SIG | none | 12,006 | 12,006 | PASS |
| DQ-P-ENTITY | Eligible share of candidates: ENTITY | none | 99.85% | 99.85% | PASS |
| DQ-P-M-C01-M-C02 | Eligible share of candidates: M-C01 / M-C02 | none | 99.13% | 99.13% | PASS |
| DQ-P-M-C01-sensitivity | Eligible share of candidates: M-C01 (sensitivity) | none | 99.20% | 99.20% | PASS |
| DQ-P-M-E01 | Eligible share of candidates: M-E01 | none | 51.94% | 51.94% | PASS |
| DQ-P-M-E02 | Eligible share of candidates: M-E02 | none | 45.15% | 45.15% | PASS |
| DQ-P-M-E03 | Eligible share of candidates: M-E03 | none | 100.00% | 100.00% | PASS |
| DQ-P-M-I01 | Eligible share of candidates: M-I01 | none | 100.00% | 100.00% | PASS |
| DQ-P-M-P01 | Eligible share of candidates: M-P01 | none | 99.43% | 99.43% | PASS |
| DQ-P-M-S01 | Eligible share of candidates: M-S01 | none | 85.88% | 85.88% | PASS |
| DQ-P-M-V01 | Eligible share of candidates: M-V01 | none | 95.38% | 95.38% | PASS |
| DQ-P-P4-BvA | Eligible share of candidates: P4-BvA | none | 98.80% | 98.80% | PASS |
| DQ-P-P5-SIG | Eligible share of candidates: P5-SIG | none | 74.02% | 74.02% | PASS |
| DQ-X1 | M-P01 extreme budgets (DQ-06): lines excluded | metric = M-P01, issue = DQ-06 | 32 | 32 | PASS |
| DQ-X2 | M-P01 extreme budgets (DQ-06): value excluded, NGN | metric = M-P01, issue = DQ-06 | 96,441,897,756,392 | 96,441,897,756,392 | PASS |
| DQ-X3 | M-V01 extreme award (DQ-07): awards excluded | metric = M-V01, issue = DQ-07 | 1 | 1 | PASS |
| DQ-X4 | M-V01 portal test entity (DQ-20): awards removed before the candidate population | metric = M-V01, issue = DQ-20 | 188 | 188 | PASS |
| DQ-X5 | M-E02 chronology conflicts (award before tender start): excluded | metric = M-E02, issue = DATE-ORDER | 135 | 135 | PASS |
| DQ-X6 | M-E01 records excluded for any reason (candidate minus eligible) | metric = M-E01, issue = ALL | 8,365 | 8,365 | PASS |
| DQ-X7 | M-S01 awards with several name variants (DQ-13, disclosed, kept) | metric = M-S01, issue = DQ-13 | 4,177 | 4,177 | PASS |

## 3. DQ-21 sensitivity: 277/277 cells PASS

The Phase 10.1 result sets (`sql/06_analysis/01`, `03`, `05`), re-run live and recomputed from the JSON with the DQ-21 flag in `awards.json` and `budget_award.json`. Each cell is compared at the precision the result set rounds to (NGN billions, percentages); names and IDs exactly.

### 01/RS6

2 row(s) x 11 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `scenario` | 1  as published (RS2) | 1  as published (RS2) | PASS |
| row 1 `awards_in_scope` | 13537 | 13537 | PASS |
| row 1 `flagged_awards_in_m_s01` | 39 | 39 | PASS |
| row 1 `value_in_scope_ngn_bn` | 2620.2 | 2620.2 | PASS |
| row 1 `top_1_share_pct` | 8.03 | 8.03 | PASS |
| row 1 `top_5_share_pct` | 21.46 | 21.46 | PASS |
| row 1 `top_10_share_pct` | 29 | 29.00 | PASS |
| row 1 `top_100_share_pct` | 59.45 | 59.45 | PASS |
| row 1 `herfindahl_index_0_to_10000` | 139.4 | 139.4 | PASS |
| row 1 `largest_supplier` | Lemaco Engineering Ltd | Lemaco Engineering Ltd | PASS |
| row 1 `largest_supplier_value_ngn_bn` | 210.29 | 210.29 | PASS |
| row 2 `scenario` | 2  without DQ-21 flagged awards | 2  without DQ-21 flagged awards | PASS |
| row 2 `awards_in_scope` | 13498 | 13498 | PASS |
| row 2 `flagged_awards_in_m_s01` | 39 | 39 | PASS |
| row 2 `value_in_scope_ngn_bn` | 2147.1 | 2147.1 | PASS |
| row 2 `top_1_share_pct` | 5.22 | 5.22 | PASS |
| row 2 `top_5_share_pct` | 18.73 | 18.73 | PASS |
| row 2 `top_10_share_pct` | 26.13 | 26.13 | PASS |
| row 2 `top_100_share_pct` | 53.22 | 53.22 | PASS |
| row 2 `herfindahl_index_0_to_10000` | 101.3 | 101.3 | PASS |
| row 2 `largest_supplier` | M/s RCC Limited | M/s RCC Limited | PASS |
| row 2 `largest_supplier_value_ngn_bn` | 112.09 | 112.09 | PASS |

### 01/RS6b

11 row(s) x 8 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `procurement_method` | National Competitive Bidding | National Competitive Bidding | PASS |
| row 1 `flagged_awards` | 26 | 26 | PASS |
| row 1 `value_published_ngn_bn` | 1630.1 | 1630.10 | PASS |
| row 1 `value_without_flagged_ngn_bn` | 1450.09 | 1450.09 | PASS |
| row 1 `top_1_share_pct_published` | 6.9 | 6.9 | PASS |
| row 1 `top_1_share_pct_without_flagged` | 7.7 | 7.7 | PASS |
| row 1 `herfindahl_published` | 146 | 146 | PASS |
| row 1 `herfindahl_without_flagged` | 167 | 167 | PASS |
| row 2 `procurement_method` | Selective Tendering | Selective Tendering | PASS |
| row 2 `flagged_awards` | 9 | 9 | PASS |
| row 2 `value_published_ngn_bn` | 451.91 | 451.91 | PASS |
| row 2 `value_without_flagged_ngn_bn` | 371.14 | 371.14 | PASS |
| row 2 `top_1_share_pct_published` | 11.1 | 11.1 | PASS |
| row 2 `top_1_share_pct_without_flagged` | 13.5 | 13.5 | PASS |
| row 2 `herfindahl_published` | 282 | 282 | PASS |
| row 2 `herfindahl_without_flagged` | 336 | 336 | PASS |
| row 3 `procurement_method` | Emergency | Emergency | PASS |
| row 3 `flagged_awards` | 2 | 2 | PASS |
| row 3 `value_published_ngn_bn` | 342.26 | 342.26 | PASS |
| row 3 `value_without_flagged_ngn_bn` | 130.18 | 130.18 | PASS |
| row 3 `top_1_share_pct_published` | 61.4 | 61.4 | PASS |
| row 3 `top_1_share_pct_without_flagged` | 55.3 | 55.3 | PASS |
| row 3 `herfindahl_published` | 4238 | 4238 | PASS |
| row 3 `herfindahl_without_flagged` | 3197 | 3197 | PASS |
| row 4 `procurement_method` | Direct Procurement | Direct Procurement | PASS |
| row 4 `flagged_awards` | 0 | 0 | PASS |
| row 4 `value_published_ngn_bn` | 117.85 | 117.85 | PASS |
| row 4 `value_without_flagged_ngn_bn` | 117.85 | 117.85 | PASS |
| row 4 `top_1_share_pct_published` | 17.5 | 17.5 | PASS |
| row 4 `top_1_share_pct_without_flagged` | 17.5 | 17.5 | PASS |
| row 4 `herfindahl_published` | 637 | 637 | PASS |
| row 4 `herfindahl_without_flagged` | 637 | 637 | PASS |
| row 5 `procurement_method` | (method not stated) | (method not stated) | PASS |
| row 5 `flagged_awards` | 0 | 0 | PASS |
| row 5 `value_published_ngn_bn` | 31.04 | 31.04 | PASS |
| row 5 `value_without_flagged_ngn_bn` | 31.04 | 31.04 | PASS |
| row 5 `top_1_share_pct_published` | 57.5 | 57.5 | PASS |
| row 5 `top_1_share_pct_without_flagged` | 57.5 | 57.5 | PASS |
| row 5 `herfindahl_published` | 3677 | 3677 | PASS |
| row 5 `herfindahl_without_flagged` | 3677 | 3677 | PASS |
| row 6 `procurement_method` | International Competitive Bidding | International Competitive Bidding | PASS |
| row 6 `flagged_awards` | 0 | 0 | PASS |
| row 6 `value_published_ngn_bn` | 16.13 | 16.13 | PASS |
| row 6 `value_without_flagged_ngn_bn` | 16.13 | 16.13 | PASS |
| row 6 `top_1_share_pct_published` | 9.3 | 9.3 | PASS |
| row 6 `top_1_share_pct_without_flagged` | 9.3 | 9.3 | PASS |
| row 6 `herfindahl_published` | 707 | 707 | PASS |
| row 6 `herfindahl_without_flagged` | 707 | 707 | PASS |
| row 7 `procurement_method` | Request for quotation | Request for quotation | PASS |
| row 7 `flagged_awards` | 1 | 1 | PASS |
| row 7 `value_published_ngn_bn` | 14.3 | 14.30 | PASS |
| row 7 `value_without_flagged_ngn_bn` | 14.28 | 14.28 | PASS |
| row 7 `top_1_share_pct_published` | 2.5 | 2.5 | PASS |
| row 7 `top_1_share_pct_without_flagged` | 2.5 | 2.5 | PASS |
| row 7 `herfindahl_published` | 56 | 56 | PASS |
| row 7 `herfindahl_without_flagged` | 56 | 56 | PASS |
| row 8 `procurement_method` | Repeat Procurement | Repeat Procurement | PASS |
| row 8 `flagged_awards` | 0 | 0 | PASS |
| row 8 `value_published_ngn_bn` | 11.97 | 11.97 | PASS |
| row 8 `value_without_flagged_ngn_bn` | 11.97 | 11.97 | PASS |
| row 8 `top_1_share_pct_published` | 8.9 | 8.9 | PASS |
| row 8 `top_1_share_pct_without_flagged` | 8.9 | 8.9 | PASS |
| row 8 `herfindahl_published` | 222 | 222 | PASS |
| row 8 `herfindahl_without_flagged` | 222 | 222 | PASS |
| row 9 `procurement_method` | National Shopping | National Shopping | PASS |
| row 9 `flagged_awards` | 1 | 1 | PASS |
| row 9 `value_published_ngn_bn` | 2.68 | 2.68 | PASS |
| row 9 `value_without_flagged_ngn_bn` | 2.44 | 2.44 | PASS |
| row 9 `top_1_share_pct_published` | 8.9 | 8.9 | PASS |
| row 9 `top_1_share_pct_without_flagged` | 5.8 | 5.8 | PASS |
| row 9 `herfindahl_published` | 155 | 155 | PASS |
| row 9 `herfindahl_without_flagged` | 91 | 91 | PASS |
| row 10 `procurement_method` | Sole Source | Sole Source | PASS |
| row 10 `flagged_awards` | 0 | 0 | PASS |
| row 10 `value_published_ngn_bn` | 1.79 | 1.79 | PASS |
| row 10 `value_without_flagged_ngn_bn` | 1.79 | 1.79 | PASS |
| row 10 `top_1_share_pct_published` | 25.1 | 25.1 | PASS |
| row 10 `top_1_share_pct_without_flagged` | 25.1 | 25.1 | PASS |
| row 10 `herfindahl_published` | 1267 | 1267 | PASS |
| row 10 `herfindahl_without_flagged` | 1267 | 1267 | PASS |
| row 11 `procurement_method` | Direct Labour | Direct Labour | PASS |
| row 11 `flagged_awards` | 0 | 0 | PASS |
| row 11 `value_published_ngn_bn` | 0.15 | 0.15 | PASS |
| row 11 `value_without_flagged_ngn_bn` | 0.15 | 0.15 | PASS |
| row 11 `top_1_share_pct_published` | 23.3 | 23.3 | PASS |
| row 11 `top_1_share_pct_without_flagged` | 23.3 | 23.3 | PASS |
| row 11 `herfindahl_published` | 1303 | 1303 | PASS |
| row 11 `herfindahl_without_flagged` | 1303 | 1303 | PASS |

### 03/RS11

2 row(s) x 10 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `scenario` | 1  as published (RS1, RS3) | 1  as published (RS1, RS3) | PASS |
| row 1 `comparable_ocids` | 15574 | 15574 | PASS |
| row 1 `flagged_ocids_in_comparison` | 45 | 45 | PASS |
| row 1 `total_budget_ngn_bn` | 12434.5 | 12434.5 | PASS |
| row 1 `total_award_ngn_bn` | 3091.5 | 3091.5 | PASS |
| row 1 `aggregate_award_to_budget_ratio` | 0.2486 | 0.2486 | PASS |
| row 1 `median_ratio` | 0.9298 | 0.9298 | PASS |
| row 1 `ocids_above_10x` | 227 | 227 | PASS |
| row 1 `above_10x_award_ngn_bn` | 1540.1 | 1540.1 | PASS |
| row 1 `above_10x_pct_of_award_value` | 49.82 | 49.82 | PASS |
| row 2 `scenario` | 2  without DQ-21 flagged awards | 2  without DQ-21 flagged awards | PASS |
| row 2 `comparable_ocids` | 15529 | 15529 | PASS |
| row 2 `flagged_ocids_in_comparison` | 45 | 45 | PASS |
| row 2 `total_budget_ngn_bn` | 12412.7 | 12412.7 | PASS |
| row 2 `total_award_ngn_bn` | 2582.1 | 2582.1 | PASS |
| row 2 `aggregate_award_to_budget_ratio` | 0.208 | 0.2080 | PASS |
| row 2 `median_ratio` | 0.9285 | 0.9285 | PASS |
| row 2 `ocids_above_10x` | 186 | 186 | PASS |
| row 2 `above_10x_award_ngn_bn` | 1030.9 | 1030.9 | PASS |
| row 2 `above_10x_pct_of_award_value` | 39.93 | 39.93 | PASS |

### 03/RS11a

1 row(s) x 7 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `flagged_awards` | 45 | 45 | PASS |
| row 1 `dropped_decimal` | 39 | 39 | PASS |
| row 1 `sibling_lot` | 6 | 6 | PASS |
| row 1 `flagged_value_ngn_bn` | 509.5 | 509.5 | PASS |
| row 1 `pct_of_m_v01_award_value` | 15.5 | 15.5 | PASS |
| row 1 `in_budget_comparison` | 45 | 45 | PASS |
| row 1 `entities` | 31 | 31 | PASS |

### 03/RS11b

5 row(s) x 8 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `rank_in_band` | 1 | 1 | PASS |
| row 1 `buyer_id` | NG-BPP-BPP-NOC-231001001 | NG-BPP-BPP-NOC-231001001 | PASS |
| row 1 `buyer_name` | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | PASS |
| row 1 `ocids_above_10x` | 93 | 93 | PASS |
| row 1 `award_ngn_bn` | 904.1 | 904.1 | PASS |
| row 1 `pct_of_band_value` | 87.7 | 87.7 | PASS |
| row 1 `band_ocids` | 186 | 186 | PASS |
| row 1 `band_award_ngn_bn` | 1030.9 | 1030.9 | PASS |
| row 2 `rank_in_band` | 2 | 2 | PASS |
| row 2 `buyer_id` | NG-BPP-BPP-NOC-3 | NG-BPP-BPP-NOC-3 | PASS |
| row 2 `buyer_name` | FEDERAL MINISTRY OF AGRICULTURE | FEDERAL MINISTRY OF AGRICULTURE | PASS |
| row 2 `ocids_above_10x` | 2 | 2 | PASS |
| row 2 `award_ngn_bn` | 50.1 | 50.1 | PASS |
| row 2 `pct_of_band_value` | 4.9 | 4.9 | PASS |
| row 2 `band_ocids` | 186 | 186 | PASS |
| row 2 `band_award_ngn_bn` | 1030.9 | 1030.9 | PASS |
| row 3 `rank_in_band` | 3 | 3 | PASS |
| row 3 `buyer_id` | NG-BPP-BPP-NOC-252041001 | NG-BPP-BPP-NOC-252041001 | PASS |
| row 3 `buyer_name` | HADEJIA-JAMAÄ»ARE RBDA | HADEJIA-JAMAÄ»ARE RBDA | PASS |
| row 3 `ocids_above_10x` | 4 | 4 | PASS |
| row 3 `award_ngn_bn` | 28.2 | 28.2 | PASS |
| row 3 `pct_of_band_value` | 2.7 | 2.7 | PASS |
| row 3 `band_ocids` | 186 | 186 | PASS |
| row 3 `band_award_ngn_bn` | 1030.9 | 1030.9 | PASS |
| row 4 `rank_in_band` | 4 | 4 | PASS |
| row 4 `buyer_id` | NG-BPP-BPP-NOC-123031011 | NG-BPP-BPP-NOC-123031011 | PASS |
| row 4 `buyer_name` | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | PASS |
| row 4 `ocids_above_10x` | 1 | 1 | PASS |
| row 4 `award_ngn_bn` | 11.3 | 11.3 | PASS |
| row 4 `pct_of_band_value` | 1.1 | 1.1 | PASS |
| row 4 `band_ocids` | 186 | 186 | PASS |
| row 4 `band_award_ngn_bn` | 1030.9 | 1030.9 | PASS |
| row 5 `rank_in_band` | 5 | 5 | PASS |
| row 5 `buyer_id` | NG-BPP-BPP-NOC-2 | NG-BPP-BPP-NOC-2 | PASS |
| row 5 `buyer_name` | FEDERAL CAPITAL TERRITORY ADMINISTRATION | FEDERAL CAPITAL TERRITORY ADMINISTRATION | PASS |
| row 5 `ocids_above_10x` | 10 | 10 | PASS |
| row 5 `award_ngn_bn` | 9.5 | 9.5 | PASS |
| row 5 `pct_of_band_value` | 0.9 | 0.9 | PASS |
| row 5 `band_ocids` | 186 | 186 | PASS |
| row 5 `band_award_ngn_bn` | 1030.9 | 1030.9 | PASS |

### 05/RS7

6 row(s) x 5 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `largest_entities` | 1 | 1 | PASS |
| row 1 `pct_of_award_value_published` | 40.6 | 40.6 | PASS |
| row 1 `pct_of_award_value_without_flagged` | 47.1 | 47.1 | PASS |
| row 1 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 1 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |
| row 2 `largest_entities` | 5 | 5 | PASS |
| row 2 `pct_of_award_value_published` | 66.6 | 66.6 | PASS |
| row 2 `pct_of_award_value_without_flagged` | 68.3 | 68.3 | PASS |
| row 2 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 2 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |
| row 3 `largest_entities` | 10 | 10 | PASS |
| row 3 `pct_of_award_value_published` | 76 | 76.0 | PASS |
| row 3 `pct_of_award_value_without_flagged` | 76.2 | 76.2 | PASS |
| row 3 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 3 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |
| row 4 `largest_entities` | 20 | 20 | PASS |
| row 4 `pct_of_award_value_published` | 83.7 | 83.7 | PASS |
| row 4 `pct_of_award_value_without_flagged` | 82.8 | 82.8 | PASS |
| row 4 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 4 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |
| row 5 `largest_entities` | 50 | 50 | PASS |
| row 5 `pct_of_award_value_published` | 92.6 | 92.6 | PASS |
| row 5 `pct_of_award_value_without_flagged` | 91.7 | 91.7 | PASS |
| row 5 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 5 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |
| row 6 `largest_entities` | 100 | 100 | PASS |
| row 6 `pct_of_award_value_published` | 97.6 | 97.6 | PASS |
| row 6 `pct_of_award_value_without_flagged` | 97.2 | 97.2 | PASS |
| row 6 `total_award_value_published_ngn_bn` | 3289.4 | 3289.4 | PASS |
| row 6 `total_award_value_without_flagged_ngn_bn` | 2780 | 2780.0 | PASS |

### 05/RS7b

10 row(s) x 7 column(s).

| cell | SQL | web |  |
|---|---|---|---|
| row 1 `rank_without` | 1 | 1 | PASS |
| row 1 `rank_published` | 1 | 1 | PASS |
| row 1 `buyer_id` | NG-BPP-BPP-NOC-231001001 | NG-BPP-BPP-NOC-231001001 | PASS |
| row 1 `buyer_name` | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | PASS |
| row 1 `award_value_published_ngn_bn` | 1335.1 | 1335.1 | PASS |
| row 1 `flagged_awards` | 5 | 5 | PASS |
| row 1 `award_value_without_flagged_ngn_bn` | 1309.4 | 1309.4 | PASS |
| row 2 `rank_without` | 2 | 2 | PASS |
| row 2 `rank_published` | 2 | 2 | PASS |
| row 2 `buyer_id` | NG-BPP-BPP-NOC-2 | NG-BPP-BPP-NOC-2 | PASS |
| row 2 `buyer_name` | FEDERAL CAPITAL TERRITORY ADMINISTRATION | FEDERAL CAPITAL TERRITORY ADMINISTRATION | PASS |
| row 2 `award_value_published_ngn_bn` | 470.1 | 470.1 | PASS |
| row 2 `flagged_awards` | 3 | 3 | PASS |
| row 2 `award_value_without_flagged_ngn_bn` | 257.8 | 257.8 | PASS |
| row 3 `rank_without` | 3 | 3 | PASS |
| row 3 `rank_published` | 3 | 3 | PASS |
| row 3 `buyer_id` | NG-BPP-BPP-NOC-521027034 | NG-BPP-BPP-NOC-521027034 | PASS |
| row 3 `buyer_name` | FEDERAL MEDICAL CENTRE, TARABA STATE | FEDERAL MEDICAL CENTRE, TARABA STATE | PASS |
| row 3 `award_value_published_ngn_bn` | 175.8 | 175.8 | PASS |
| row 3 `flagged_awards` | 0 | 0 | PASS |
| row 3 `award_value_without_flagged_ngn_bn` | 175.8 | 175.8 | PASS |
| row 4 `rank_without` | 4 | 4 | PASS |
| row 4 `rank_published` | 4 | 4 | PASS |
| row 4 `buyer_id` | NG-BPP-BPP-NOC-220007049 | NG-BPP-BPP-NOC-220007049 | PASS |
| row 4 `buyer_name` | FEDERAL INLAND REVENUE SERVICE | FEDERAL INLAND REVENUE SERVICE | PASS |
| row 4 `award_value_published_ngn_bn` | 125 | 125.0 | PASS |
| row 4 `flagged_awards` | 2 | 2 | PASS |
| row 4 `award_value_without_flagged_ngn_bn` | 88 | 88.0 | PASS |
| row 5 `rank_without` | 5 | 5 | PASS |
| row 5 `rank_published` | 7 | 7 | PASS |
| row 5 `buyer_id` | NG-BPP-BPP-NOC-539001003 | NG-BPP-BPP-NOC-539001003 | PASS |
| row 5 `buyer_name` | BORDER COMMUNITIES DEVELOPMENT AGENCY | BORDER COMMUNITIES DEVELOPMENT AGENCY | PASS |
| row 5 `award_value_published_ngn_bn` | 71.6 | 71.6 | PASS |
| row 5 `flagged_awards` | 1 | 1 | PASS |
| row 5 `award_value_without_flagged_ngn_bn` | 66.8 | 66.8 | PASS |
| row 6 `rank_without` | 6 | 6 | PASS |
| row 6 `rank_published` | 8 | 8 | PASS |
| row 6 `buyer_id` | NG-BPP-BPP-NOC-3 | NG-BPP-BPP-NOC-3 | PASS |
| row 6 `buyer_name` | FEDERAL MINISTRY OF AGRICULTURE | FEDERAL MINISTRY OF AGRICULTURE | PASS |
| row 6 `award_value_published_ngn_bn` | 66.5 | 66.5 | PASS |
| row 6 `flagged_awards` | 0 | 0 | PASS |
| row 6 `award_value_without_flagged_ngn_bn` | 66.5 | 66.5 | PASS |
| row 7 `rank_without` | 7 | 7 | PASS |
| row 7 `rank_published` | 6 | 6 | PASS |
| row 7 `buyer_id` | NG-BPP-BPP-NOC-232007001 | NG-BPP-BPP-NOC-232007001 | PASS |
| row 7 `buyer_name` | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | PASS |
| row 7 `award_value_published_ngn_bn` | 77.9 | 77.9 | PASS |
| row 7 `flagged_awards` | 1 | 1 | PASS |
| row 7 `award_value_without_flagged_ngn_bn` | 66.2 | 66.2 | PASS |
| row 8 `rank_without` | 8 | 8 | PASS |
| row 8 `rank_published` | 5 | 5 | PASS |
| row 8 `buyer_id` | NG-BPP-BPP-NOC-252041001 | NG-BPP-BPP-NOC-252041001 | PASS |
| row 8 `buyer_name` | HADEJIA-JAMAÄ»ARE RBDA | HADEJIA-JAMAÄ»ARE RBDA | PASS |
| row 8 `award_value_published_ngn_bn` | 86.2 | 86.2 | PASS |
| row 8 `flagged_awards` | 5 | 5 | PASS |
| row 8 `award_value_without_flagged_ngn_bn` | 32.4 | 32.4 | PASS |
| row 9 `rank_without` | 9 | 9 | PASS |
| row 9 `rank_published` | 10 | 10 | PASS |
| row 9 `buyer_id` | NG-BPP-BPP-NOC-553001001 | NG-BPP-BPP-NOC-553001001 | PASS |
| row 9 `buyer_name` | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | PASS |
| row 9 `award_value_published_ngn_bn` | 43 | 43.0 | PASS |
| row 9 `flagged_awards` | 2 | 2 | PASS |
| row 9 `award_value_without_flagged_ngn_bn` | 28.6 | 28.6 | PASS |
| row 10 `rank_without` | 10 | 10 | PASS |
| row 10 `rank_published` | 15 | 15 | PASS |
| row 10 `buyer_id` | NG-BPP-BPP-NOC-124002001 | NG-BPP-BPP-NOC-124002001 | PASS |
| row 10 `buyer_name` | NIGERIAN CORRECTIONAL SERVICE | NIGERIAN CORRECTIONAL SERVICE | PASS |
| row 10 `award_value_published_ngn_bn` | 25.9 | 25.9 | PASS |
| row 10 `flagged_awards` | 0 | 0 | PASS |
| row 10 `award_value_without_flagged_ngn_bn` | 25.9 | 25.9 | PASS |

## 4. In-browser self-check (`web/check.html`)

`web/check.html` loads the same JSON with the site's own modules (`js/data.js`, `js/metrics.js`, `js/format.js`) and compares every figure in `expected.json` (the 177 and the sensitivity cells) under the same tolerance. Serve `web/` (`python -m http.server --directory web 8000`) and open `http://localhost:8000/check.html`.

**Recorded result:** PASS: figures 177/177 PASS; DQ-21 sensitivity 277/277 cells PASS; 14 data files verified against manifest SHA-256. Chromium 152 (desktop app browser pane) at 1440 px and at 375 px, web/ served locally with the web/vercel.json headers (Content-Security-Policy enforced) (expected.json SHA-256 `7567a9078e358092…`, recorded 2026-10-22 12:31)

## 5. Wording scan

Words from `dashboard/README.md` §7.3 (19): fraud, corrupt/corruption, collusion, bid rigging, kickback, embezzle, misconduct, irregularity, suspicious, red flag, overpriced, inflated, overrun, loss, saving, wasteful, underperforming, non-performing, failed contractor. The 11 mandatory caveat sentences of §8 are allowed verbatim. Files scanned: `web\check.html`, `web\css\check.css`, `web\css\site.css`, `web\index.html`, `web\js\app.js`, `web\js\charts.js`, `web\js\check.js`, `web\js\check_page.js`, `web\js\data.js`, `web\js\format.js`, `web\js\metrics.js`, `web\js\pages\budget.js`, `web\js\pages\common.js`, `web\js\pages\competition.js`, `web\js\pages\data_quality.js`, `web\js\pages\entities.js`, `web\js\pages\implementation.js`, `web\js\pages\overview.js`, `web\js\pages\suppliers.js`, `web\js\pages\timing.js`, `web\js\state.js`, `web\js\text.js`, `web\js\theme.js`, `web\js\ui.js`.

No findings.

---

*Generated by `python/web/check_web_data.py`. Database, raw dataset and existing outputs not modified.*
