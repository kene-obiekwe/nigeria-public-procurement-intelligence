# Phase 8 — Business-Question Analysis Results

> **Runner:** `python/validation/05_run_analysis_scripts.py`  
> **Run date:** 2026-10-08 18:52:45  
> **Database:** `nocopo_db` on localhost:5433 (PostgreSQL 17.4)  
> **Scripts:** 7; 50 result sets run; no failures.

Every script reads only `analytics.*` views and runs in a read-only transaction. Interpretation, limitations and spot-checks: `docs/phase8_analysis/phase8_business_question_analysis.md`.

## 01_supplier_concentration.sql

*Question: How concentrated is awarded procurement value among suppliers, and*

### RS1 — Eligible population and the disclosed exclusion (every M-S01 figure must carry this)

*1 row(s), 0.5 s*

| metric | candidate_awards | eligible_awards | eligible_pct_of_candidate | distinct_suppliers | eligible_value_ngn_bn | excluded_awards_bare_supplier_id | excluded_value_ngn_bn | excluded_pct_of_candidate_value |
|---|---|---|---|---|---|---|---|---|
| M-S01 | 15,763 | 13,537 | 85.9 | 9,800 | 2,620.2 | 2,226 | 670.4 | 20.4 |

### RS1b — Register entry for M-S01 (analytics.vw_metric_population; a few seconds)

*1 row(s), 1.8 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-S01 | M-V01 eligible awards | 15,763 | 13,537 | 85.9 |

### RS2 — Overall concentration: share held by the largest suppliers, Herfindahl index, depth to 50% / 80%

*1 row(s), 0.3 s*

| suppliers | awards_in_scope | value_in_scope_ngn_bn | top_1_share_pct | top_5_share_pct | top_10_share_pct | top_20_share_pct | top_100_share_pct | herfindahl_index_0_to_10000 | suppliers_to_reach_50_pct | suppliers_to_reach_80_pct | suppliers_with_one_award |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9,800 | 13,537 | 2,620.2 | 8.03 | 21.46 | 29 | 37.5 | 59.45 | 139.4 | 45 | 872 | 7,631 |

### RS3 — Top 20 suppliers by awarded value (rank, share, cumulative share)

*20 row(s), 0.3 s*

| value_rank | supplier_id | supplier_name | awards | procuring_entities | value_ngn_bn | share_pct | cumulative_share_pct | identity_note |
|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-73422 | Lemaco Engineering Ltd | 2 | 1 | 210.29 | 8.03 | 8.03 | several name variants (DQ-13): share may be understated |
| 2 | NG-BPP-BPP-CI-1797 | M/s RCC Limited | 1 | 1 | 112.09 | 4.28 | 12.3 | single name |
| 3 | NG-BPP-BPP-CI-1775 | M/s Julius Berger Nig. Plc. | 1 | 1 | 88.09 | 3.36 | 15.67 | single name |
| 4 | NG-BPP-BPP-CI-452 | MESSRS KOPEK CONSTRUCTION LIMITED | 1 | 1 | 79.83 | 3.05 | 18.71 | single name |
| 5 | NG-BPP-73594 | Insil Services Ltd | 1 | 1 | 72 | 2.75 | 21.46 | single name |
| 6 | NG-BPP-BPP-CI-9059 | LLW Inter Biz LTD | 2 | 1 | 50.09 | 1.91 | 23.37 | several name variants (DQ-13): share may be understated |
| 7 | NG-BPP-47259 | VOLATIX PRODUCTS LIMITED | 1 | 1 | 44.49 | 1.7 | 25.07 | single name |
| 8 | NG-BPP-BPP-CI-71 | Ric Rock Construction Nigeria Limited | 2 | 1 | 36.38 | 1.39 | 26.46 | several name variants (DQ-13): share may be understated |
| 9 | NG-BPP-BPP-CI-68 | CGC Nigeria Limited | 3 | 2 | 33.67 | 1.29 | 27.74 | several name variants (DQ-13): share may be understated |
| 10 | NG-BPP-BPP-CI-414 | ARAB CONTRACTORS O.A.O. NIGERIA LIMITED | 2 | 1 | 33.05 | 1.26 | 29 | several name variants (DQ-13): share may be understated |
| 11 | NG-BPP-BPP-CI-394 | SETRACO NIGERIA LIMITED | 3 | 1 | 28.53 | 1.09 | 30.09 | several name variants (DQ-13): share may be understated |
| 12 | NG-BPP-BPP-CI-422 | GILOMO ENGINEERING NIGERIA LIMITED | 1 | 1 | 27.29 | 1.04 | 31.14 | single name |
| 13 | NG-BPP-BPP-CI-4364 | M SULUM NIGERIA LIMITED | 1 | 1 | 24.75 | 0.94 | 32.08 | single name |
| 14 | NG-BPP-BPP-CI-4349 | Mellon De Company International Ltd | 2 | 2 | 22.77 | 0.87 | 32.95 | several name variants (DQ-13): share may be understated |
| 15 | NG-BPP-RC370127 | LAURMANN AND COMPANY LIMITED | 3 | 1 | 20.62 | 0.79 | 33.74 | single name |
| 16 | NG-BPP-BPP-CI-447 | MESSRS CBC GLOBAL CIVIL & BUILDING CONSTRUCTION NIGERIA LIMITED | 1 | 1 | 20.39 | 0.78 | 34.51 | single name |
| 17 | NG-BPP-RC509693 | BACKBONE CONNECTIVITY NETWORK | 4 | 1 | 20.24 | 0.77 | 35.29 | several name variants (DQ-13): share may be understated |
| 18 | NG-BPP-BPP-CI-419 | TRIACTA NIGERIA LIMITED | 5 | 1 | 20.08 | 0.77 | 36.05 | several name variants (DQ-13): share may be understated |
| 19 | NG-BPP-BPP-CI-10776 | Hakris Nigeria Limited | 1 | 1 | 19.51 | 0.74 | 36.8 | single name |
| 20 | NG-BPP-BPP-CI-66 | Rockbridge Construction Nigeria Limited | 2 | 1 | 18.33 | 0.7 | 37.5 | several name variants (DQ-13): share may be understated |

### RS4 — Concentration by procurement method (the only category-like field available)

*11 row(s), 0.8 s*

| procurement_method | eligible_awards | suppliers | value_ngn_bn | top_1_share_pct | top_5_share_pct | herfindahl_index | reliability_note |
|---|---|---|---|---|---|---|---|
| National Competitive Bidding | 7,761 | 6,059 | 1,630.1 | 6.9 | 22.1 | 146 |  |
| Selective Tendering | 3,073 | 2,530 | 451.91 | 11.1 | 32.5 | 282 |  |
| Emergency | 363 | 257 | 342.26 | 61.4 | 88 | 4,238 |  |
| Direct Procurement | 867 | 669 | 117.85 | 17.5 | 50 | 637 |  |
| (method not stated) | 105 | 105 | 31.04 | 57.5 | 81.7 | 3,677 |  |
| International Competitive Bidding | 61 | 60 | 16.13 | 9.3 | 46.2 | 707 |  |
| Request for quotation | 554 | 483 | 14.3 | 2.5 | 9.8 | 56 |  |
| Repeat Procurement | 208 | 171 | 11.97 | 8.9 | 23.6 | 222 |  |
| National Shopping | 494 | 385 | 2.68 | 8.9 | 20.6 | 155 |  |
| Sole Source | 39 | 29 | 1.79 | 25.1 | 70.3 | 1,267 |  |
| Direct Labour | 12 | 12 | 0.15 | 23.3 | 72.4 | 1,303 | small n: read with caution |

### RS5 — Concentration by procuring entity (entities with at least min_awards eligible awards)

*15 row(s), 0.6 s*

| concentration_rank | buyer_id | buyer_name | eligible_awards | suppliers | value_ngn_bn | top_1_supplier_share_pct | top_3_suppliers_share_pct | herfindahl_index | percentile_among_entities | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-161015001 | NIGERIA CHRISTIAN PILGRIM COMMISSION | 10 | 8 | 5.75 | 96.2 | 99 | 9,263 | 100 | 166 |
| 2 | NG-BPP-BPP-NOC-517019013 | ADEYEMI COLLEGE OF EDUCATION ONDO | 14 | 14 | 13 | 93.2 | 95.6 | 8,699 | 99 | 166 |
| 3 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 14 | 14 | 48.91 | 91 | 96 | 8,294 | 99 | 166 |
| 4 | NG-BPP-BPP-NOC-23 | MINISTRY OF INTERIOR | 10 | 9 | 0.28 | 90.4 | 94.4 | 8,189 | 98 | 166 |
| 5 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 277 | 252 | 66.4 | 75.4 | 76.4 | 5,696 | 98 | 166 |
| 6 | NG-BPP-BPP-NOC-228063001 | PROTOTYPE ENGINEERING DEVELOPMENT INSTITUTE , ILESHA | 29 | 25 | 1.4 | 74.6 | 83.2 | 5,622 | 97 | 166 |
| 7 | NG-BPP-BPP-NOC-31 | FEDERAL MINISTRY OF AVIATION | 18 | 10 | 19.54 | 67 | 88.4 | 4,768 | 96 | 166 |
| 8 | NG-BPP-BPP-NOC-124003001 | NIGERIA IMMIGRATION SERVICE | 78 | 66 | 21.32 | 56.5 | 64.6 | 3,257 | 96 | 166 |
| 9 | NG-BPP-BPP-NOC-521027033 | FEDERAL MEDICAL CENTRE, KEBBI STATE | 37 | 27 | 6.27 | 56.3 | 72.4 | 3,343 | 95 | 166 |
| 10 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 75 | 70 | 35.53 | 54.9 | 74.8 | 3,350 | 95 | 166 |
| 11 | NG-BPP-BPP-NOC-229001001 | FEDERAL MINISTRY OF TRANSPORTATION - HQTRS | 10 | 10 | 0.91 | 53.3 | 76.5 | 3,262 | 94 | 166 |
| 12 | NG-BPP-BPP-NOC-517019010 | FEDERAL COLLEGE OF EDUCATION OBUDU | 67 | 61 | 8.09 | 51.9 | 60.3 | 2,798 | 93 | 166 |
| 13 | NG-BPP-BPP-NOC-517018039 | FEDERAL POLYTECHNIC OF OIL AND GAS, BONNY, RIVERS STATE | 13 | 8 | 0.85 | 51.3 | 70.7 | 3,046 | 93 | 166 |
| 14 | NG-BPP-BPP-NOC-521027022 | FEDERAL MEDICAL CENTRE, KATSINA | 204 | 151 | 13.24 | 49.5 | 60.9 | 2,587 | 92 | 166 |
| 15 | NG-BPP-BPP-NOC-513001001 | FEDERAL MINISTRY OF YOUTH & SPORTS DEVELOPMENT - HQTRS | 90 | 83 | 10.69 | 49.1 | 56.7 | 2,492 | 92 | 166 |

### RS5b — Distribution of entity-level concentration (same entities as RS5)

*1 row(s), 0.5 s*

| entities_in_comparison | min_awards_threshold | p25_top_1_share_pct | median_top_1_share_pct | p75_top_1_share_pct | entities_where_one_supplier_holds_half |
|---|---|---|---|---|---|
| 166 | 10 | 13.8 | 21 | 29 | 13 |


## 02_competition.sql

*Question: How competitive are procurement processes based on available*

### RS1 — Eligible populations and headline metrics

*2 row(s), 0.2 s*

| population | eligible_tenders | median_tenderers_m_c01 | single_bidder_rate_pct_m_c02 | mean_tenderers | max_tenderers |
|---|---|---|---|---|---|
| primary (NORMAL, 1-100) | 17,253 | 2 | 44.04 | 3.23 | 90 |
| sensitivity (NORMAL + ELEVATED) | 17,266 | 2 | 44.01 | 3.54 | 897 |

### RS1b — Register entry (analytics.vw_metric_population; a few seconds)

*2 row(s), 3.0 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-C01 (sensitivity) | Snapshot OCIDs with a tender | 17,405 | 17,266 | 99.2 |
| M-C01 / M-C02 | Snapshot OCIDs with a tender | 17,405 | 17,253 | 99.1 |

### RS2 — Participation bands (CASE classification) with cumulative share

*8 row(s), 0.2 s*

| participation_band | primary_tenders | pct_of_primary | cumulative_pct_of_primary | sensitivity_only_tenders |
|---|---|---|---|---|
| 1  single bidder | 7,599 | 44.04 | 44.04 | 0 |
| 2  two tenderers | 1,138 | 6.6 | 50.64 | 0 |
| 3  3-5 tenderers | 6,567 | 38.06 | 88.7 | 0 |
| 4  6-10 tenderers | 1,319 | 7.65 | 96.35 | 0 |
| 5  11-20 tenderers | 467 | 2.71 | 99.06 | 0 |
| 6  21-50 tenderers | 150 | 0.87 | 99.92 | 0 |
| 7  51-100 tenderers | 13 | 0.08 | 100 | 0 |
| 8  101-1,000 (ELEVATED, sensitivity only) | 0 | 0 | 100 | 13 |

### RS3 — Percentiles of tenderers (primary)

*1 row(s), 0.1 s*

| eligible_tenders | min_tenderers | p25 | median | p75 | p90 | p99 | max_tenderers |
|---|---|---|---|---|---|---|---|
| 17,253 | 1 | 1 | 2 | 4 | 6 | 20 | 90 |

### RS4 — Competition by procurement method (primary population)

*11 row(s), 0.1 s*

| procurement_method | eligible_tenders | median_tenderers | single_bidder_rate_pct | six_plus_tenderers_pct | single_bidder_gap_vs_overall_pts | reliability_note |
|---|---|---|---|---|---|---|
| National Competitive Bidding | 10,129 | 3 | 39.6 | 16.9 | -4.5 |  |
| Selective Tendering | 3,775 | 3 | 44.5 | 4.5 | 0.5 |  |
| Direct Procurement | 1,095 | 1 | 89.5 | 0.9 | 45.5 |  |
| Request for quotation | 713 | 3 | 31.1 | 0.7 | -12.9 |  |
| National Shopping | 594 | 3 | 23.7 | 1.5 | -20.3 |  |
| Emergency | 395 | 1 | 51.6 | 2.3 | 7.6 |  |
| Repeat Procurement | 280 | 1 | 87.1 | 0.4 | 43.1 |  |
| (method not stated) | 132 | 3 | 31.8 | 13.6 | -12.2 |  |
| International Competitive Bidding | 75 | 3 | 29.3 | 17.3 | -14.7 |  |
| Sole Source | 47 | 1 | 87.2 | 0 | 43.2 |  |
| Direct Labour | 18 | 1 | 77.8 | 0 | 33.7 | small n: read with caution |

### RS5 — Competition by tender status (Kene I-3: all non-null statuses kept; segmentation only)

*6 row(s), 0.2 s*

| tender_status | primary_tenders | median_tenderers | single_bidder_rate_pct | reliability_note |
|---|---|---|---|---|
| complete | 10,091 | 3 | 42.7 |  |
| active | 6,585 | 2 | 46.2 |  |
| planned | 489 | 2 | 43.4 |  |
| unsuccessful | 37 | 1 | 56.8 |  |
| cancelled | 32 | 2 | 43.8 |  |
| withdrawn | 19 | 5 | 26.3 | small n: read with caution |

### RS6 — Entities at the extremes of competition (primary population, DQ-19 buyer excluded)

*20 row(s), 0.2 s*

| ranking | rank_in_group | buyer_id | buyer_name | eligible_tenders | median_tenderers | single_bidder_rate_pct | single_bidder_quartile | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|
| lowest single-bidder rate | 1 | NG-BPP-BPP-NOC-517021010 | UNIVERSITY OF ABUJA | 212 | 3 | 0 | 1 | 103 |
| lowest single-bidder rate | 2 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 59 | 5 | 0 | 1 | 103 |
| lowest single-bidder rate | 3 | NG-BPP-BPP-NOC-521027038 | FEDERAL MEDICAL CENTRE, EBUTE METTA | 43 | 6 | 0 | 1 | 103 |
| lowest single-bidder rate | 4 | NG-BPP-BPP-NOC-CBAAC | CENTRE FOR BLACK AFRICAN ARTS AND CIVILISATION | 41 | 3 | 0 | 1 | 103 |
| lowest single-bidder rate | 5 | NG-BPP-BPP-NOC-215059001 | NATIONAL AGRICULTURAL LAND DEVELOPMENT AUTHORITY | 32 | 5 | 0 | 1 | 103 |
| lowest single-bidder rate | 6 | NG-BPP-BPP-NOC-124011002 | NIGERIA POLICE ACADEMY WUDIL, KANO | 31 | 3 | 0 | 1 | 103 |
| lowest single-bidder rate | 7 | NG-BPP-BPP-NOC-252045001 | OGUN/ OSUN RBDA | 364 | 3 | 1.1 | 1 | 103 |
| lowest single-bidder rate | 8 | NG-BPP-BPP-NOC-232001003 | PETROLEUM TECHNOLOGY DEVELOPMENT FUND | 89 | 3 | 2.2 | 1 | 103 |
| lowest single-bidder rate | 9 | NG-BPP-BPP-NOC-521026011 | UNIVERSITY OF MAIDUGURI TEACHING HOSPITAL | 34 | 3 | 2.9 | 1 | 103 |
| lowest single-bidder rate | 10 | NG-BPP-BPP-NOC-228073001 | ENERGY COMMISSION OF NIGERIA | 164 | 9 | 3 | 1 | 103 |
| highest single-bidder rate | 1 | NG-BPP-BPP-NOC-228039002 | NATIONAL BOARD FOR TECHNOLOGY INCUBATION | 245 | 1 | 100 | 4 | 103 |
| highest single-bidder rate | 2 | NG-BPP-BPP-NOC-521003001 | NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY | 32 | 1 | 100 | 4 | 103 |
| highest single-bidder rate | 3 | NG-BPP-BPP-NOC-222013001 | ONNE OIL AND GAS FREE ZONE AUTHORITY | 71 | 1 | 98.6 | 4 | 103 |
| highest single-bidder rate | 4 | NG-BPP-BPP-NOC-252047001 | UPPER BENUE RBDA | 150 | 1 | 97.3 | 4 | 103 |
| highest single-bidder rate | 5 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 442 | 1 | 96.4 | 4 | 103 |
| highest single-bidder rate | 6 | NG-BPP-BPP-NOC-228046001 | FEDERAL INSTITUTE OF INDUSTRIAL RESEARCH -OSHODI | 90 | 1 | 95.6 | 4 | 103 |
| highest single-bidder rate | 7 | NG-BPP-BPP-NOC-111010001 | BUREAU OF PUBLIC PROCUREMENT (BPP) | 63 | 1 | 95.2 | 4 | 103 |
| highest single-bidder rate | 8 | NG-BPP-BPP-NOC-145001001 | PUBLIC COMPLAINTS COMMISSION | 60 | 1 | 95 | 4 | 103 |
| highest single-bidder rate | 9 | NG-BPP-BPP-NOC-163001002 | NIGERIA POLICE TRUST FUND | 93 | 1 | 93.5 | 4 | 103 |
| highest single-bidder rate | 10 | NG-BPP-BPP-NOC-119008001 | NIGERIAN INSTITUTE OF INTERNATIONAL AFFAIRS, LAGOS | 31 | 1 | 93.5 | 4 | 103 |


## 03_budget_to_award.sql

*Question: How does awarded value compare with recorded planning budgets, and*

### RS1 — Eligible population, totals and headline ratios

*1 row(s), 0.3 s*

| candidate_awards | eligible_ocids | eligible_pct_of_candidate | excluded_ocids | total_budget_ngn_bn | total_award_ngn_bn | net_variance_ngn_bn | aggregate_award_to_budget_ratio | median_ratio |
|---|---|---|---|---|---|---|---|---|
| 15,763 | 15,574 | 98.8 | 189 | 12,434.5 | 3,091.5 | -9,343 | 0.2486 | 0.9298 |

### RS1b — Register entry (analytics.vw_metric_population; a few seconds)

*1 row(s), 2.6 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| P4-BvA | M-V01 eligible awards | 15,763 | 15,574 | 98.8 |

### RS2 — Distribution of the award-to-budget ratio (percentiles; nothing trimmed)

*1 row(s), 0.3 s*

| eligible_ocids | min_ratio | p01 | p10 | p25 | median | p75 | p90 | p99 | max_ratio |
|---|---|---|---|---|---|---|---|---|---|
| 15,574 | 0 | 0.0017 | 0.0273 | 0.2168 | 0.9298 | 1 | 1.1151 | 17.4497 | 1,710,000,000 |

### RS3 — Ratio bands (CASE classification): how many OCIDs, how much value in each

*6 row(s), 0.2 s*

| ratio_band | ocids | pct_of_ocids | budget_ngn_bn | award_ngn_bn | pct_of_award_value |
|---|---|---|---|---|---|
| 1  award below half of budget (<0.5) | 5,300 | 34.03 | 11,378.96 | 316.55 | 10.24 |
| 2  award 50-90% of budget | 2,118 | 13.6 | 286.94 | 207.84 | 6.72 |
| 3  award within 10% of budget (0.9-1.1) | 6,564 | 42.15 | 524.58 | 521.84 | 16.88 |
| 4  award 110-150% of budget | 453 | 2.91 | 64.77 | 80.16 | 2.59 |
| 5  award 1.5x-10x budget | 912 | 5.86 | 138.45 | 425.02 | 13.75 |
| 6  award above 10x budget (check units / budget entry) | 227 | 1.46 | 40.83 | 1,540.11 | 49.82 |

### RS4 — Variance by procurement method

*11 row(s), 0.2 s*

| procurement_method | eligible_ocids | budget_ngn_bn | award_ngn_bn | net_variance_ngn_bn | aggregate_ratio | median_ratio | pct_award_above_110pct_of_budget | pct_award_below_90pct_of_budget | reliability_note |
|---|---|---|---|---|---|---|---|---|---|
| National Competitive Bidding | 9,159 | 9,301.67 | 1,897.02 | -7,404.65 | 0.2039 | 0.9152 | 11.4 | 48.9 |  |
| Selective Tendering | 3,369 | 824.17 | 535.94 | -288.23 | 0.6503 | 0.9829 | 10.2 | 41.3 |  |
| Direct Procurement | 970 | 627.8 | 214.48 | -413.31 | 0.3416 | 0.9407 | 7.1 | 45.1 |  |
| Request for quotation | 663 | 35.59 | 16.81 | -18.78 | 0.4723 | 0.9896 | 4.4 | 31.1 |  |
| National Shopping | 546 | 80.38 | 3.45 | -76.93 | 0.0429 | 0.1444 | 4.9 | 77.3 |  |
| Emergency | 379 | 1,231.78 | 344.64 | -887.14 | 0.2798 | 0.2313 | 7.4 | 66.8 |  |
| Repeat Procurement | 242 | 76.45 | 15.88 | -60.57 | 0.2077 | 0.9639 | 7 | 43.8 |  |
| (method not stated) | 122 | 124.02 | 34.2 | -89.82 | 0.2757 | 0.8612 | 10.7 | 51.6 |  |
| International Competitive Bidding | 67 | 52.23 | 27.04 | -25.19 | 0.5178 | 0.9771 | 19.4 | 44.8 |  |
| Sole Source | 43 | 80.15 | 1.88 | -78.27 | 0.0234 | 0.9798 | 9.3 | 41.9 |  |
| Direct Labour | 14 | 0.29 | 0.19 | -0.1 | 0.6639 | 0.8242 | 7.1 | 57.1 | small n: read with caution |

### RS5 — Entities with the largest net variance between awards and budgets (absolute NGN)

*15 row(s), 0.3 s*

| rank_by_abs_variance | buyer_id | buyer_name | eligible_ocids | budget_ngn_bn | award_ngn_bn | net_variance_ngn_bn | aggregate_ratio | median_ratio | cumulative_share_of_abs_variance_pct | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,678 | 6,894.8 | 1,334.92 | -5,559.89 | 0.1936 | 0.0985 | 56.5 | 171 |
| 2 | NG-BPP-BPP-NOC-124002001 | NIGERIAN CORRECTIONAL SERVICE | 234 | 855.98 | 25.41 | -830.57 | 0.0297 | 0.0198 | 64.9 | 171 |
| 3 | NG-BPP-BPP-NOC-521027047 | NIGERIA CENTRE FOR DISEASE CONTROL ABUJA | 134 | 702.55 | 10.91 | -691.64 | 0.0155 | 0.0055 | 71.9 | 171 |
| 4 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 843 | 1,042.22 | 470.08 | -572.14 | 0.451 | 0.2479 | 77.7 | 171 |
| 5 | NG-BPP-BPP-NOC-232007001 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 624 | 379.44 | 77.53 | -301.91 | 0.2043 | 0.8841 | 80.8 | 171 |
| 6 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 423 | 315.39 | 28.18 | -287.2 | 0.0894 | 0.0607 | 83.7 | 171 |
| 7 | NG-BPP-BPP-NOC-252001001 | FEDERAL MINISTRY OF WATER RESOURCES - HQTRS | 393 | 280.74 | 21.11 | -259.64 | 0.0752 | 0.0205 | 86.4 | 171 |
| 8 | NG-BPP-BPP-NOC-220007049 | FEDERAL INLAND REVENUE SERVICE | 791 | 297.54 | 124.36 | -173.18 | 0.4179 | 0.9899 | 88.1 | 171 |
| 9 | NG-BPP-BPP-NOC-116001001 | FEDERAL MINISTRY OF DEFENCE - MAIN MOD | 289 | 127.68 | 20.85 | -106.83 | 0.1633 | 0.2193 | 89.2 | 171 |
| 10 | NG-BPP-BPP-NOC-215002001 | FEDERAL COLLEGE OF PRODUCE INSPECTION AND STORED PRODUCTS TECHNOLOGY, KANO | 66 | 103.97 | 4.33 | -99.64 | 0.0416 | 0.9985 | 90.2 | 171 |
| 11 | NG-BPP-BPP-NOC-222001002 | CORPORATE AFFAIRS COMMISSION | 251 | 99.43 | 6.12 | -93.31 | 0.0616 | 0.0465 | 91.2 | 171 |
| 12 | NG-BPP-BPP-NOC-553001001 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 173 | 129.1 | 42.66 | -86.44 | 0.3304 | 1 | 92 | 171 |
| 13 | NG-BPP-BPP-NOC-163001002 | NIGERIA POLICE TRUST FUND | 89 | 99.11 | 14.09 | -85.02 | 0.1422 | 1 | 92.9 | 171 |
| 14 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 58 | 4.03 | 86.17 | 82.14 | 21.3731 | 1 | 93.7 | 171 |
| 15 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 20 | 3.29 | 49.84 | 46.55 | 15.1523 | 1 | 94.2 | 171 |

### RS6 — Entities whose typical process departs most from budget (median ratio), same comparison set

*15 row(s), 0.3 s*

| rank_by_median_departure | buyer_id | buyer_name | eligible_ocids | median_ratio | pct_ocids_within_10pct_of_budget | alignment_quartile | entities_in_comparison |
|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-521027047 | NIGERIA CENTRE FOR DISEASE CONTROL ABUJA | 134 | 0.0055 | 0.7 | 1 | 171 |
| 2 | NG-BPP-BPP-NOC-124002001 | NIGERIAN CORRECTIONAL SERVICE | 234 | 0.0198 | 0.4 | 1 | 171 |
| 3 | NG-BPP-BPP-NOC-252001001 | FEDERAL MINISTRY OF WATER RESOURCES - HQTRS | 393 | 0.0205 | 4.6 | 1 | 171 |
| 4 | NG-BPP-BPP-NOC-222001002 | CORPORATE AFFAIRS COMMISSION | 251 | 0.0465 | 10.4 | 1 | 171 |
| 5 | NG-BPP-BPP-NOC-232001001 | MINSITRY OF ENERGY (PETROLEUM RESOURCES) HQTRS | 23 | 0.0487 | 0 | 1 | 171 |
| 6 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 423 | 0.0607 | 10.9 | 1 | 171 |
| 7 | NG-BPP-BPP-NOC-222013001 | ONNE OIL AND GAS FREE ZONE AUTHORITY | 69 | 0.0613 | 8.7 | 1 | 171 |
| 8 | NG-BPP-BPP-NOC-124004001 | NIGERIA SECURITY AND CIVIL DEFENCE CORPS | 115 | 0.0798 | 0.9 | 1 | 171 |
| 9 | NG-BPP-BPP-NOC-611001002 | COURT OF APPEAL | 17 | 0.0829 | 0 | 1 | 171 |
| 10 | NG-BPP-BPP-NOC-119009001 | NIGERIANS IN DIASPORA COMMISSION | 12 | 0.0928 | 16.7 | 1 | 171 |
| 11 | NG-BPP-BPP-NOC-222001001 | FEDERAL MINISTRY OF INDUSTRY, TRADE AND INVESTMENT - HQTRS | 22 | 0.0973 | 27.3 | 2 | 171 |
| 12 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,678 | 0.0985 | 11.9 | 1 | 171 |
| 13 | NG-BPP-BPP-NOC-517021025 | NATIONAL MATHEMATICAL CENTRE, SHEDA | 68 | 0.1096 | 0 | 1 | 171 |
| 14 | NG-BPP-BPP-NOC-31 | FEDERAL MINISTRY OF AVIATION | 20 | 0.1414 | 0 | 1 | 171 |
| 15 | NG-BPP-BPP-NOC-229031006 | ACCIDENT INVESTIGATION BUREAU | 170 | 0.1515 | 7.1 | 1 | 171 |

### RS7 — Double-count check: is any planning budget line compared against more than one OCID?

*1 row(s), 0.3 s*

| budget_project_ids | ids_used_by_several_ocids | summed_budget_ngn_bn | budget_counted_once_ngn_bn | reading |
|---|---|---|---|---|
| 15,574 | 0 | 12,434.5 | 12,434.5 | no budget line is repeated across OCIDs: totals are not inflated by sharing |

### RS8 — Placeholder-like budgets: how many comparable OCIDs record a budget under NGN 100,000, and what ratios result

*1 row(s), 0.6 s*

| comparable_ocids | ocids_with_budget_under_100k | smallest_budget_ngn | largest_ratio_among_them | of_which_ratio_1m_or_more | all_ocids_with_ratio_1m_or_more | ratio_1m_or_more_with_budget_100k_plus |
|---|---|---|---|---|---|---|
| 15,574 | 16 | 1 | 1,710,000,000 | 4 | 4 | 0 |

### RS9 — The above-10x band by entity: where the band's value sits (pattern only; no cause is attributed)

*5 row(s), 0.2 s*

| rank_in_band | buyer_id | buyer_name | ocids_above_10x | award_ngn_bn | pct_of_band_value | median_ratio | band_ocids | band_award_ngn_bn |
|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 98 | 929.8 | 60.4 | 23.3 | 227 | 1,540.1 |
| 2 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 13 | 221.8 | 14.4 | 29.7 | 227 | 1,540.1 |
| 3 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 9 | 81.9 | 5.3 | 79.9 | 227 | 1,540.1 |
| 4 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 2 | 50.1 | 3.3 | 229.8 | 227 | 1,540.1 |
| 5 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 4 | 47.1 | 3.1 | 64.8 | 227 | 1,540.1 |

### RS10 — Unit test: is an award about 1,000 times its budget (budget recorded in thousands)?

*1 row(s), 0.2 s*

| ocids_with_ratio_900_to_1100 | of_which_budget_100k_plus | ocids_above_10x | ratio_900_to_1100_pct_of_above_10x | reading |
|---|---|---|---|---|
| 9 | 6 | 227 | 4 | a "budget recorded in thousands" pattern would put most of the above-10x OCIDs near 1,000; it does not |


## 04_procurement_cycle_timing.sql

*Question: What can valid tender, award and contract dates tell us about*

### RS1 — Eligible population sizes and medians (headline timing metrics)

*3 row(s), 0.7 s*

| measure | eligible_n | median_days |
|---|---|---|
| M-E01 tender open duration (days) | 9,040 | 28 |
| M-E02 award lag, tender start to award (days) | 7,462 | 97 |
| P5-SIG signature lag, award to signing (days) | 12,006 | 5 |

### RS1b — Coverage: candidate population, eligible count and eligible share (analytics.vw_metric_population; a few seconds)

*3 row(s), 3.0 s*

| metric_id | metric_name | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|---|
| M-E01 | Median tender duration (days) | Snapshot OCIDs with a tender | 17,405 | 9,040 | 51.9 |
| M-E02 | Median award lag (days) | Snapshot OCIDs with a tender and an award | 16,527 | 7,462 | 45.2 |
| P5-SIG | Contract signature lag (days) | Snapshot contracts | 16,221 | 12,006 | 74 |

### RS2 — Distribution of each interval, with counts of unusually long intervals (kept, not removed)

*3 row(s), 0.7 s*

| measure | eligible_n | min_days | p25 | median | p75 | p90 | p99 | max_days | mean_days | same_day | over_1_year | over_1_year_pct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-E01 tender open duration | 9,040 | 1 | 14 | 28 | 43 | 64 | 336 | 3,696 | 40.4 | 0 | 66 | 0.73 |
| M-E02 award lag | 7,462 | 0 | 42 | 97 | 150 | 267 | 574.3900000000003 | 3,756 | 124.7 | 92 | 294 | 3.94 |
| P5-SIG signature lag | 12,006 | 0 | 0 | 5 | 27 | 62 | 376.9500000000007 | 6,574 | 27.5 | 3,826 | 156 | 1.3 |

### RS3 — Duration bands (CASE classification)

*18 row(s), 0.7 s*

| measure | duration_band | processes | pct_of_measure | cumulative_pct |
|---|---|---|---|---|
| M-E01 tender open duration | 1  up to 7 days | 1,105 | 12.22 | 12.22 |
| M-E01 tender open duration | 2  8-30 days | 3,745 | 41.43 | 53.65 |
| M-E01 tender open duration | 3  31-90 days | 3,655 | 40.43 | 94.08 |
| M-E01 tender open duration | 4  91-180 days | 367 | 4.06 | 98.14 |
| M-E01 tender open duration | 5  181-365 days | 102 | 1.13 | 99.27 |
| M-E01 tender open duration | 6  over 1 year | 66 | 0.73 | 100 |
| M-E02 award lag | 1  up to 7 days | 257 | 3.44 | 3.44 |
| M-E02 award lag | 2  8-30 days | 1,196 | 16.03 | 19.47 |
| M-E02 award lag | 3  31-90 days | 1,934 | 25.92 | 45.39 |
| M-E02 award lag | 4  91-180 days | 2,659 | 35.63 | 81.02 |
| M-E02 award lag | 5  181-365 days | 1,122 | 15.04 | 96.06 |
| M-E02 award lag | 6  over 1 year | 294 | 3.94 | 100 |
| P5-SIG signature lag | 1  up to 7 days | 6,854 | 57.09 | 57.09 |
| P5-SIG signature lag | 2  8-30 days | 2,427 | 20.21 | 77.3 |
| P5-SIG signature lag | 3  31-90 days | 2,233 | 18.6 | 95.9 |
| P5-SIG signature lag | 4  91-180 days | 249 | 2.07 | 97.98 |
| P5-SIG signature lag | 5  181-365 days | 87 | 0.72 | 98.7 |
| P5-SIG signature lag | 6  over 1 year | 156 | 1.3 | 100 |

### RS4 — Timing by procurement method (eligible populations only; n shown for each measure)

*11 row(s), 0.5 s*

| procurement_method | tender_duration_n | median_tender_duration_days | award_lag_n | median_award_lag_days | reliability_note |
|---|---|---|---|---|---|
| National Competitive Bidding | 5,989 | 42 | 4,856 | 120 |  |
| Selective Tendering | 1,617 | 21 | 1,339 | 43 |  |
| National Shopping | 360 | 7 | 319 | 14 |  |
| Emergency | 294 | 4 | 278 | 9 |  |
| Request for quotation | 289 | 14 | 249 | 28 |  |
| Direct Procurement | 271 | 21 | 241 | 112 |  |
| Repeat Procurement | 87 | 47 | 75 | 62 |  |
| (method not stated) | 64 | 26.5 | 53 | 98 |  |
| International Competitive Bidding | 56 | 35 | 42 | 156 |  |
| Sole Source | 8 | 15 | 6 | 26 | small n in at least one measure: read with caution |
| Direct Labour | 5 | 29 | 4 | 58.5 | small n in at least one measure: read with caution |

### RS5 — Tender open duration by year of tender start, with year-on-year change in the median

*15 row(s), 0.1 s*

| tender_start_year | eligible_n | median_days | change_vs_previous_year_days | reliability_note |
|---|---|---|---|---|
| 2010 | 3 | 41 |  | small n: read with caution |
| 2011 | 5 | 42 | 1 | small n: read with caution |
| 2013 | 1 | 42 |  | small n: read with caution |
| 2014 | 1 | 31 | -11 | small n: read with caution |
| 2015 | 4 | 46.5 | 15.5 | small n: read with caution |
| 2016 | 31 | 42 | -4.5 |  |
| 2017 | 485 | 50 | 8 |  |
| 2018 | 830 | 43 | -7 |  |
| 2019 | 1,025 | 42 | -1 |  |
| 2020 | 1,459 | 18 | -24 |  |
| 2021 | 1,578 | 42 | 24 |  |
| 2022 | 1,734 | 28 | -14 |  |
| 2023 | 1,189 | 28 | 0 |  |
| 2024 | 680 | 28 | 0 |  |
| 2025 | 15 | 28 | 0 | small n: read with caution |

### RS6 — Award lag by year of award date, with year-on-year change in the median

*11 row(s), 0.4 s*

| award_year | eligible_n | median_days | change_vs_previous_year_days | reliability_note |
|---|---|---|---|---|
| 2011 | 3 | 133 |  | small n: read with caution |
| 2016 | 11 | 59 |  | small n: read with caution |
| 2017 | 142 | 86 | 27 |  |
| 2018 | 551 | 104 | 18 |  |
| 2019 | 1,263 | 137 | 33 |  |
| 2020 | 1,430 | 41 | -96 |  |
| 2021 | 975 | 92 | 51 |  |
| 2022 | 1,258 | 114 | 22 |  |
| 2023 | 1,208 | 107 | -7 |  |
| 2024 | 605 | 100 | -7 |  |
| 2025 | 16 | 80 | -20 | small n: read with caution |


## 05_entity_benchmarking.sql

*Question: Which procuring entities account for the greatest procurement*

### RS0 — Minimum eligible n applied to each KPI in this script (analytic parameters, not data rules)

*4 row(s), 0.0 s*

| kpi | min_n |
|---|---|
| single_bidder_rate / median_tenderers (competition_n) | 30 |
| top_supplier_value_share (award_n) | 10 |
| implementation_coverage_rate (contract_n) | 20 |
| tender_reach_rate (process_count) | 30 |

### RS1 — Population: entities and how many have data for each KPI

*1 row(s), 0.6 s*

| entities | processes_in_scope | entities_with_budget_lines | entities_with_competition_data | entities_competition_n_30_plus | entities_with_awards | entities_award_n_10_plus | entities_with_contracts | entities_contract_n_20_plus | total_award_value_ngn_bn | total_planned_budget_ngn_bn |
|---|---|---|---|---|---|---|---|---|---|---|
| 665 | 98,428 | 664 | 280 | 103 | 259 | 173 | 257 | 123 | 3,289.4 | 93,279.5 |

### RS1b — Register entry (analytics.vw_metric_population; a few seconds)

*1 row(s), 3.1 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| ENTITY | Buyer IDs (core.dim_buyer, DQ-20 test entity excluded) | 666 | 665 | 99.8 |

### RS2 — How much activity sits with the largest entities (window functions: rank and cumulative share)

*6 row(s), 0.4 s*

| largest_entities | pct_of_award_value | pct_of_processes | pct_of_planned_budget |
|---|---|---|---|
| 1 | 40.6 | 5.2 | 27.6 |
| 5 | 66.6 | 17.4 | 59.7 |
| 10 | 76 | 26.9 | 72.5 |
| 20 | 83.7 | 39.3 | 81.3 |
| 50 | 92.6 | 57.1 | 90.5 |
| 100 | 97.6 | 71.8 | 95.6 |

### RS3 — Top 15 entities by awarded value, with their rank on each activity measure

*15 row(s), 0.4 s*

| rank_award_value | buyer_id | buyer_name | award_value_ngn_bn | cumulative_share_of_award_value_pct | award_n | process_count | planned_budget_ngn_bn | rank_processes | rank_awards | rank_budget |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,335.1 | 40.6 | 1,682 | 4,626 | 25,785.7 | 2 | 1 | 1 |
| 2 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 470.1 | 54.9 | 844 | 5,148 | 14,540.9 | 1 | 2 | 2 |
| 3 | NG-BPP-BPP-NOC-521027034 | FEDERAL MEDICAL CENTRE, TARABA STATE | 175.8 | 60.2 | 10 | 28 | 6 | 377 | 167 | 282 |
| 4 | NG-BPP-BPP-NOC-220007049 | FEDERAL INLAND REVENUE SERVICE | 125 | 64 | 799 | 2,470 | 634.8 | 4 | 3 | 18 |
| 5 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 86.2 | 66.6 | 58 | 1,012 | 71.2 | 17 | 57 | 86 |
| 6 | NG-BPP-BPP-NOC-232007001 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 77.9 | 69 | 627 | 1,526 | 1,158.6 | 12 | 5 | 12 |
| 7 | NG-BPP-BPP-NOC-539001003 | BORDER COMMUNITIES DEVELOPMENT AGENCY | 71.6 | 71.2 | 744 | 2,513 | 182.8 | 3 | 4 | 43 |
| 8 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 66.5 | 73.2 | 281 | 2,409 | 7,534.1 | 5 | 11 | 3 |
| 9 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 50 | 74.7 | 21 | 73 | 9.3 | 243 | 116 | 234 |
| 10 | NG-BPP-BPP-NOC-553001001 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 43 | 76 | 178 | 294 | 662.1 | 73 | 21 | 17 |
| 11 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 36.7 | 77.2 | 83 | 309 | 118.4 | 69 | 43 | 63 |
| 12 | NG-BPP-BPP-NOC-227004001 | NATIONAL PRODUCTIVITY CENTRE | 29.9 | 78.1 | 204 | 1,930 | 177.5 | 7 | 18 | 47 |
| 13 | NG-BPP-BPP-NOC-123031011 | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | 29 | 78.9 | 106 | 183 | 9.8 | 121 | 34 | 232 |
| 14 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 28.6 | 79.8 | 431 | 1,303 | 2,064.4 | 15 | 6 | 10 |
| 15 | NG-BPP-BPP-NOC-124002001 | NIGERIAN CORRECTIONAL SERVICE | 25.9 | 80.6 | 238 | 443 | 2,749.3 | 45 | 15 | 6 |

### RS4 — KPI profile of the top 15 entities by awarded value, each KPI beside its own n and percentile position

*15 row(s), 1.3 s*

| rank_award_value | buyer_name | tender_reach_pct | reach_pctile | competition_n | median_tenderers | tenderers_pctile | single_bidder_pct | single_bidder_pctile | award_n | top_supplier_share_pct | top_supplier_pctile | contract_n | implementation_coverage_pct | implementation_pctile |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 36.8 | 80 | 1,635 | 4 | 83 | 3.7 | 10 | 1,682 | 11.1 | 17 | 1,677 | 21.6 | 2 |
| 2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 18.7 | 67 | 950 | 3 | 56 | 37.8 | 43 | 844 | 45.4 | 88 | 844 | 79 | 7 |
| 3 | FEDERAL MEDICAL CENTRE, TARABA STATE |  |  | 10 |  |  |  |  | 10 | 49.1 | 91 | 8 |  |  |
| 4 | FEDERAL INLAND REVENUE SERVICE | 37.5 | 81 | 922 | 1 | 0 | 69.5 | 68 | 799 | 18.3 | 42 | 910 | 98.6 | 43 |
| 5 | HADEJIA-JAMAÄ»ARE RBDA | 5.8 | 49 | 59 | 5 | 91 | 0 | 0 | 58 | 29 | 73 | 57 | 98.3 | 39 |
| 6 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 41.7 | 83 | 636 | 1 | 0 | 57.6 | 60 | 627 | 7.8 | 7 | 622 | 99.2 | 53 |
| 7 | BORDER COMMUNITIES DEVELOPMENT AGENCY | 30.8 | 76 | 765 | 3 | 56 | 17.3 | 35 | 744 | 8.2 | 9 | 737 | 98.6 | 47 |
| 8 | FEDERAL MINISTRY OF AGRICULTURE | 12.2 | 59 | 294 | 1 | 0 | 80.3 | 77 | 281 | 75.4 | 97 | 284 | 84.2 | 11 |
| 9 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 28.8 | 75 | 21 |  |  |  |  | 21 | 91 | 98 | 21 | 85.7 | 12 |
| 10 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 69.7 | 97 | 203 | 5 | 91 | 7.4 | 19 | 178 | 28.7 | 70 | 205 | 100 | 58 |
| 11 | NATIONAL INLAND WATERWAYS AUTHORITY | 35 | 79 | 108 | 11 | 100 | 5.6 | 15 | 83 | 54.9 | 94 | 83 | 4.8 | 1 |
| 12 | NATIONAL PRODUCTIVITY CENTRE | 13 | 60 | 249 | 2 | 49 | 40.6 | 48 | 204 | 29.6 | 74 | 196 | 93.4 | 21 |
| 13 | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | 59 | 93 | 108 | 4 | 83 | 5.6 | 15 | 106 | 45 | 87 | 108 | 99.1 | 50 |
| 14 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 34.4 | 78 | 442 | 1 | 0 | 96.4 | 96 | 431 | 46.6 | 90 | 433 | 98.6 | 45 |
| 15 | NIGERIAN CORRECTIONAL SERVICE | 54.4 | 92 | 241 | 1 | 0 | 92.5 | 89 | 238 | 8 | 9 | 235 | 94 | 23 |

### RS5 — Spread of each KPI across entities that meet the minimum n (the yardstick for RS4)

*5 row(s), 1.6 s*

| kpi | entities_compared | p10 | p25 | median | p75 | p90 |
|---|---|---|---|---|---|---|
| tender reach rate | 373 | 0 | 0 | 0.064 | 0.27 | 0.519 |
| median tenderers | 103 | 1 | 1 | 2 | 3 | 4 |
| single-bidder rate | 103 | 0.037 | 0.097 | 0.417 | 0.784 | 0.932 |
| top-supplier value share | 173 | 0.082 | 0.14 | 0.222 | 0.313 | 0.465 |
| implementation coverage rate | 123 | 0.833 | 0.951 | 0.991 | 1 | 1 |

### RS6 — Do larger entities differ? KPI medians by quartile of awarded value (entities with awards)

*4 row(s), 0.6 s*

| value_quartile | entities | award_value_ngn_bn | pct_of_award_value | entities_with_competition_n | median_single_bidder_pct | entities_with_contract_n | median_implementation_coverage_pct | reliability_note |
|---|---|---|---|---|---|---|---|---|
| 1 | 65 | 3,118.2 | 94.8 | 56 | 41 | 58 | 98.9 |  |
| 2 | 65 | 132.6 | 4 | 40 | 50.4 | 52 | 99.3 |  |
| 3 | 65 | 33.5 | 1 | 4 | 82.3 | 10 | 98.9 | fewer than 10 entities in a KPI: read with caution |
| 4 | 64 | 5.1 | 0.2 | 3 | 33.3 | 3 | 100 | fewer than 10 entities in a KPI: read with caution |


## 06_implementation_coverage.sql

*Question: What proportion of contracts has usable implementation/payment*

### RS1 — M-I01 headline: eligible population and coverage rate

*1 row(s), 0.1 s*

| eligible_contracts | contracts_with_implementation_data | coverage_rate_pct_m_i01 | contracts_without_implementation_data |
|---|---|---|---|
| 16,221 | 14,140 | 87.17 | 2,081 |

### RS1b — Register entries (analytics.vw_metric_population; a few seconds)

*2 row(s), 2.7 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-E03 | All OCIDs (no exclusions by spec) | 98,454 | 98,454 | 100 |
| M-I01 | Snapshot contracts (no exclusions by spec) | 16,221 | 16,221 | 100 |

### RS2 — What kind of implementation data exists (CASE classification)

*3 row(s), 0.2 s*

| implementation_data_type | contracts | pct_of_contracts | transactions | implementation_milestones |
|---|---|---|---|---|
| 1  transactions and milestones | 12,796 | 78.89 | 12,898 | 24,049 |
| 2  milestones only | 1,344 | 8.29 | 0 | 2,578 |
| 4  no implementation data | 2,081 | 12.83 | 0 | 0 |

### RS3 — Coverage by contract status

*4 row(s), 0.1 s*

| contract_status | contracts | with_implementation_data | coverage_rate_pct | reliability_note |
|---|---|---|---|---|
| active | 15,653 | 13,609 | 86.94 |  |
| cancelled | 338 | 334 | 98.82 |  |
| pending | 121 | 90 | 74.38 |  |
| terminated | 109 | 107 | 98.17 |  |

### RS4 — Distribution of coverage across entities (entities with at least min_contracts contracts)

*5 row(s), 0.1 s*

| entity_coverage_band | entities | pct_of_entities | contracts_held | pct_of_contracts | min_contracts_threshold |
|---|---|---|---|---|---|
| 1  full coverage (100%) | 52 | 42.3 | 3,090 | 20.3 | 20 |
| 2  90% to under 100% | 47 | 38.2 | 8,325 | 54.7 | 20 |
| 3  50% to under 90% | 18 | 14.6 | 1,904 | 12.5 | 20 |
| 4  under 50% | 5 | 4.1 | 1,887 | 12.4 | 20 |
| 5  none reported (0%) | 1 | 0.8 | 20 | 0.1 | 20 |

### RS5 — Entities with the lowest coverage (reporting gaps; not a performance ranking)

*15 row(s), 0.2 s*

| rank_lowest_coverage | buyer_id | buyer_name | contracts | with_implementation_data | coverage_rate_pct | percentile_among_entities | entities_in_comparison |
|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-535013001 | FORESTRY RESEARCH INSTITUTE OF IBADAN | 20 | 0 | 0 | 0 | 123 |
| 2 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 83 | 4 | 4.8 | 1 | 123 |
| 3 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,677 | 362 | 21.6 | 2 | 123 |
| 4 | NG-BPP-BPP-NOC-517019010 | FEDERAL COLLEGE OF EDUCATION OBUDU | 77 | 21 | 27.3 | 2 | 123 |
| 5 | NG-BPP-BPP-NOC-517024001 | NATIONAL OPEN UNIVERSITY | 21 | 8 | 38.1 | 3 | 123 |
| 6 | NG-BPP-BPP-NOC-521027029 | FEDERAL TEACHING HOSPITAL, ABAKALIKI | 29 | 12 | 41.4 | 4 | 123 |
| 7 | NG-BPP-BPP-NOC-521026008 | JOS UNIVERSITY TEACHING HOSPITAL | 29 | 15 | 51.7 | 5 | 123 |
| 8 | NG-BPP-BPP-NOC-228050001 | NIGERIA INSTITUTE OF LEATHER AND SCIENCE TECHNOLOGY (NILEST) HQTRS | 57 | 37 | 64.9 | 6 | 123 |
| 9 | NG-BPP-BPP-NOC-228063001 | PROTOTYPE ENGINEERING DEVELOPMENT INSTITUTE , ILESHA | 37 | 28 | 75.7 | 7 | 123 |
| 10 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 844 | 667 | 79 | 7 | 123 |
| 11 | NG-BPP-BPP-NOC-517021030 | FEDERAL UNIVERSITY OTUOKE | 24 | 19 | 79.2 | 8 | 123 |
| 12 | NG-BPP-BPP-NOC-517021006 | UNIVERSITY OF BENIN | 23 | 19 | 82.6 | 9 | 123 |
| 13 | NG-BPP-BPP-NOC-513001001 | FEDERAL MINISTRY OF YOUTH & SPORTS DEVELOPMENT - HQTRS | 89 | 74 | 83.1 | 10 | 123 |
| 14 | NG-BPP-BPP-NOC-535015001 | NATIONAL OIL SPILL DETECTION AND RESPONSE AGENCY | 50 | 42 | 84 | 11 | 123 |
| 15 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 284 | 239 | 84.2 | 11 | 123 |

### RS6 — Lifecycle funnel (M-E03): how far did processes get in what was published?

*5 row(s), 0.1 s*

| stage_order | stage | ocids_whose_last_published_stage_is_this | ocids_reaching_stage_or_beyond | pct_of_all_ocids | conversion_from_previous_stage_pct |
|---|---|---|---|---|---|
| 1 | planning | 81,049 | 98,454 | 100 |  |
| 2 | tender | 878 | 17,405 | 17.68 | 17.68 |
| 3 | award | 306 | 16,527 | 16.79 | 94.96 |
| 4 | contract | 2,072 | 16,221 | 16.48 | 98.15 |
| 5 | implementation | 14,149 | 14,149 | 14.37 | 87.23 |


## 07_data_quality_impact.sql

*Question: Which data-quality issues could materially affect the*

### RS1 — Exclusions by metric: candidate, eligible, and how the excluded records divide by cause

*9 row(s), 4.1 s*

| metric_order | metric_id | metric_name | candidate_records | eligible_records | eligible_pct | excluded_records | lost_to_one_dq_issue_only | lost_to_non_dq_rule_only | lost_to_two_or_more_reasons | reconciles_candidate_minus_eligible |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | M-P01 | Total planned budget by entity | 97,353 | 96,802 | 99.4 | 551 | 532 | 0 | 19 | yes |
| 2 | M-C01 / M-C02 | Median tenderers; single-bidder rate (primary) | 17,405 | 17,253 | 99.1 | 152 | 78 | 74 | 0 | yes |
| 3 | M-V01 | Median award value | 16,527 | 15,763 | 95.4 | 764 | 242 | 502 | 20 | yes |
| 4 | M-S01 | Top-supplier award value concentration | 15,763 | 13,537 | 85.9 | 2,226 | 2,226 | 0 | 0 | yes |
| 5 | P4-BvA | Budget-to-award comparison | 15,763 | 15,574 | 98.8 | 189 | 61 | 128 | 0 | yes |
| 6 | M-E01 | Median tender duration (days) | 17,405 | 9,040 | 51.9 | 8,365 | 26 | 8,339 | 0 | yes |
| 7 | M-E02 | Median award lag (days) | 16,527 | 7,462 | 45.2 | 9,065 | 179 | 8,789 | 97 | yes |
| 8 | P5-SIG | Contract signature lag (days) | 16,221 | 12,006 | 74 | 4,215 | 819 | 3,299 | 97 | yes |
| 11 | ENTITY | Procuring-entity benchmark | 666 | 665 | 99.8 | 1 | 1 | 0 | 0 | yes |

### RS2 — Issue-by-metric matrix: size of each issue's footprint, value at stake, materiality

*32 row(s), 5.3 s*

| metric_id | dq_ref | dq_issue | impact_type | treatment | candidate_records | records_with_issue | pct_of_candidate | records_lost_only_to_issue | affected_value_ngn_bn | value_pct_of_candidate | materiality | rank_within_metric | note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ALL | DQ-01 | Repeated OCIDs (multi-release processes) | DISCLOSED | RETAIN | 98,454 | 6,267 | 6.37 |  |  |  | MODERATE | 1 | Not excluded. The process snapshot (Phase 4 v1.1) takes the latest release per section, so values are not double-counted. |
| M-P01 | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 97,353 | 493 | 0.51 | 493 | 0 | 0 | LOW | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| M-P01 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 97,353 | 396 | 0.41 |  | 529.7 | 0.3 | LOW | 2 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| M-P01 | DQ-06 | Extreme budget (>= NGN 1 trillion) | EXCLUDES | EXCLUDE_FROM_METRIC | 97,353 | 32 | 0.03 | 32 | 96,441.9 | 50.8 | HIGH | 3 | Retained in core and flagged; value would dominate any total or ratio. |
| M-P01 | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 97,353 | 26 | 0.03 | 7 | 18.6 | 0 | LOW | 4 | Excluded from per-entity measures; kept in overall process counts. |
| M-P01 | DQ-18 | Release with no parties array | EXCLUDES | EXCLUDE_FROM_METRIC | 97,353 | 19 | 0.02 | 0 | 14 | 0 | LOW | 5 | Buyer cannot be derived, so the line is left out of buyer-level budget totals. |
| M-C01 / M-C02 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 17,405 | 218 | 1.25 |  |  |  | MODERATE | 1 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| M-C01 / M-C02 | DQ-05 | Anomalous tenderer count (>1,000) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,405 | 65 | 0.37 | 65 |  |  | LOW | 2 | Excluded from primary and sensitivity populations. |
| M-C01 / M-C02 | DQ-04 | Elevated tenderer count (101-1,000) | EXCLUDES_FROM_PRIMARY | FLAG | 17,405 | 13 | 0.07 | 13 |  |  | LOW | 3 | Excluded from the primary result; kept in the sensitivity population (M-C01). |
| M-V01 | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 16,527 | 261 | 1.58 | 241 | 0 | 0 | MODERATE | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| M-V01 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 16,527 | 188 | 1.14 |  | 72.8 | 1.7 | MODERATE | 2 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| M-V01 | DQ-07 | Extreme award value (FCTA NGN 1.004T) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,527 | 1 | 0.01 | 1 | 1,004.2 | 23.3 | HIGH | 3 | Retained in core and flagged; value would dominate any total or median. |
| M-S01 | DQ-13 | Supplier ID with several name variants | DISCLOSED | RETAIN | 13,537 | 4,177 | 30.86 |  | 892.4 | 34.1 | HIGH | 1 | Not merged. Supplier concentration is a lower bound where one real supplier carries several IDs (DQ-14, DQ-15). |
| M-S01 | DQ-14 | Incomplete supplier ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 15,763 | 2,226 | 14.12 | 2,226 | 670.4 | 20.4 | HIGH | 2 | Supplier identity cannot be resolved, so the award is left out of supplier concentration. State this with every M-S01 figure. |
| P4-BvA | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 15,763 | 58 | 0.37 | 58 | 15.9 | 0.5 | LOW | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| P4-BvA | C-06 | Several unrelated budget lines on one OCID (MULTI_PROJECT) | EXCLUDES | EXCLUDE_FROM_METRIC | 15,763 | 3 | 0.02 | 3 | 0.3 | 0 | LOW | 2 | Kene I-2: no rule says which budget line an award answers, so the OCID is left out of budget-to-award. |
| M-E01 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 17,405 | 218 | 1.25 |  |  |  | MODERATE | 1 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| M-E01 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,405 | 24 | 0.14 | 24 |  |  | LOW | 2 | Excluded from the timing metric that needs the date. |
| M-E01 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,405 | 2 | 0.01 | 2 |  |  | LOW | 3 | Excluded from the timing metric that needs the date. |
| M-E02 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 16,527 | 188 | 1.14 |  |  |  | MODERATE | 1 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| M-E02 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,527 | 137 | 0.83 | 42 |  |  | LOW | 2 | Excluded from the timing metric that needs the date. |
| M-E02 | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,527 | 135 | 0.82 | 135 |  |  | LOW | 3 | No DQ number. Negative durations are excluded, not corrected (Kene decision, Phase 7). |
| M-E02 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,527 | 4 | 0.02 | 2 |  |  | LOW | 4 | Excluded from the timing metric that needs the date. |
| P5-SIG | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,221 | 734 | 4.52 | 734 |  |  | MODERATE | 1 | No DQ number. Negative durations are excluded, not corrected (Kene decision, Phase 7). |
| P5-SIG | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,221 | 180 | 1.11 | 83 |  |  | MODERATE | 2 | Excluded from the timing metric that needs the date. |
| P5-SIG | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 16,221 | 171 | 1.05 |  |  |  | MODERATE | 3 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |
| P5-SIG | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,221 | 2 | 0.01 | 2 |  |  | LOW | 4 | Excluded from the timing metric that needs the date. |
| M-E03 | DQ-02 | Planning-only processes | DISCLOSED | RETAIN | 98,454 | 81,049 | 82.32 |  |  |  | HIGH | 1 | Not excluded. Most processes were published only at planning stage, so later-stage metrics describe a small share of all OCIDs. |
| M-I01 | DQ-11 | Implementation transaction dates absent | DISCLOSED | RETAIN | 16,221 | 12,796 | 78.89 |  |  |  | HIGH | 1 | Transactions are used for presence only; payment timing cannot be measured. |
| M-I01 | DQ-12 | Implementation transaction value semantics unclear | DISCLOSED | RETAIN | 16,221 | 12,796 | 78.89 |  |  |  | HIGH | 1 | Transaction values are not summed; the field meaning is unresolved. |
| ENTITY | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 666 | 1 | 0.15 | 1 |  |  | LOW | 1 | Excluded from per-entity measures; kept in overall process counts. |
| ENTITY | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | PRE_EXCLUDED | EXCLUDE_FROM_METRIC | 666 | 1 | 0.15 |  |  |  | LOW | 1 | A portal test artefact, not procurement. Retained and flagged in stg/core; removed before each candidate population is defined, so it is outside candidate minus eligible. |

### RS3 — Which issues matter most across metrics (how many metrics each touches materially)

*18 row(s), 4.6 s*

| issue_rank | dq_ref | dq_issue | treatment | metrics_touched | metrics_high | metrics_moderate | metrics_affected |
|---|---|---|---|---|---|---|---|
| 1 | DQ-02 | Planning-only processes | RETAIN | 1 | 1 | 0 | M-E03 (HIGH, 82.3% of records or value) |
| 1 | DQ-06 | Extreme budget (>= NGN 1 trillion) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-P01 (HIGH, 50.8% of records or value) |
| 1 | DQ-07 | Extreme award value (FCTA NGN 1.004T) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-V01 (HIGH, 23.3% of records or value) |
| 1 | DQ-11 | Implementation transaction dates absent | RETAIN | 1 | 1 | 0 | M-I01 (HIGH, 78.9% of records or value) |
| 1 | DQ-12 | Implementation transaction value semantics unclear | RETAIN | 1 | 1 | 0 | M-I01 (HIGH, 78.9% of records or value) |
| 1 | DQ-13 | Supplier ID with several name variants | RETAIN | 1 | 1 | 0 | M-S01 (HIGH, 34.1% of records or value) |
| 1 | DQ-14 | Incomplete supplier ID (bare NG-BPP-) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-S01 (HIGH, 20.4% of records or value) |
| 8 | DQ-20 | Portal test entity (NG-BPP-BPP-NOC-90, TEST MINISTRY - NOCOPO) | EXCLUDE_FROM_METRIC | 7 | 0 | 5 | M-P01 (LOW, 0.4% of records or value); M-C01 / M-C02 (MODERATE, 1.3% of records or value); M-V01 (MODERATE, 1.7% of records or value); M-E01 (MODERATE, 1.3% of records or value); M-E02 (MODERATE, 1.1% of records or value); P5-SIG (MODERATE, 1.1% of records or value); ENTITY (LOW, 0.2% of records or value) |
| 9 | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDE_FROM_METRIC | 2 | 0 | 1 | M-E02 (LOW, 0.8% of records or value); P5-SIG (MODERATE, 4.5% of records or value) |
| 9 | DQ-01 | Repeated OCIDs (multi-release processes) | RETAIN | 1 | 0 | 1 | ALL (MODERATE, 6.4% of records or value) |
| 9 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDE_FROM_METRIC | 3 | 0 | 1 | M-E01 (LOW, 0.1% of records or value); M-E02 (LOW, 0.8% of records or value); P5-SIG (MODERATE, 1.1% of records or value) |
| 9 | DQ-16 | Zero monetary value | EXCLUDE_FROM_METRIC | 3 | 0 | 1 | M-P01 (LOW, 0.5% of records or value); M-V01 (MODERATE, 1.6% of records or value); P4-BvA (LOW, 0.5% of records or value) |
| 13 | C-06 | Several unrelated budget lines on one OCID (MULTI_PROJECT) | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | P4-BvA (LOW, 0.0% of records or value) |
| 13 | DQ-04 | Elevated tenderer count (101-1,000) | FLAG | 1 | 0 | 0 | M-C01 / M-C02 (LOW, 0.1% of records or value) |
| 13 | DQ-05 | Anomalous tenderer count (>1,000) | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | M-C01 / M-C02 (LOW, 0.4% of records or value) |
| 13 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDE_FROM_METRIC | 3 | 0 | 0 | M-E01 (LOW, 0.0% of records or value); M-E02 (LOW, 0.0% of records or value); P5-SIG (LOW, 0.0% of records or value) |
| 13 | DQ-18 | Release with no parties array | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | M-P01 (LOW, 0.0% of records or value) |
| 13 | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDE_FROM_METRIC | 2 | 0 | 0 | M-P01 (LOW, 0.0% of records or value); ENTITY (LOW, 0.2% of records or value) |


---

*Generated by `python/validation/05_run_analysis_scripts.py`. Raw dataset, stg.* and core.* not modified.*
