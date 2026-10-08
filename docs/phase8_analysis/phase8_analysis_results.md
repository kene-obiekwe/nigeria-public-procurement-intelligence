# Phase 8 — Business-Question Analysis Results

> **Runner:** `python/validation/05_run_analysis_scripts.py`  
> **Run date:** 2026-10-08 17:36:45  
> **Database:** `nocopo_db` on localhost:5433 (PostgreSQL 17.4)  
> **Scripts:** 7; 47 result sets run; no failures.

Every script reads only `analytics.*` views and runs in a read-only transaction. Interpretation, limitations and spot-checks: `docs/phase8_analysis/phase8_business_question_analysis.md`.

## 01_supplier_concentration.sql

*Question: How concentrated is awarded procurement value among suppliers, and*

### RS1 — Eligible population and the disclosed exclusion (every M-S01 figure must carry this)

*1 row(s), 2.7 s*

| metric | candidate_awards | eligible_awards | eligible_pct_of_candidate | distinct_suppliers | eligible_value_ngn_bn | excluded_awards_bare_supplier_id | excluded_value_ngn_bn | excluded_pct_of_candidate_value |
|---|---|---|---|---|---|---|---|---|
| M-S01 | 15,946 | 13,694 | 85.9 | 9,941 | 2,686.8 | 2,252 | 675.8 | 20.1 |

### RS1b — Register entry for M-S01 (analytics.vw_metric_population; about 40 s because the register evaluates every view)

*1 row(s), 40.5 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-S01 | M-V01 eligible awards | 15,946 | 13,694 | 85.9 |

### RS2 — Overall concentration: share held by the largest suppliers, Herfindahl index, depth to 50% / 80%

*1 row(s), 2.6 s*

| suppliers | awards_in_scope | value_in_scope_ngn_bn | top_1_share_pct | top_5_share_pct | top_10_share_pct | top_20_share_pct | top_100_share_pct | herfindahl_index_0_to_10000 | suppliers_to_reach_50_pct | suppliers_to_reach_80_pct | suppliers_with_one_award |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9,941 | 13,694 | 2,686.8 | 7.83 | 20.93 | 28.54 | 37.37 | 59.37 | 134.8 | 45 | 880 | 7,763 |

### RS3 — Top 20 suppliers by awarded value (rank, share, cumulative share)

*20 row(s), 2.7 s*

| value_rank | supplier_id | supplier_name | awards | procuring_entities | value_ngn_bn | share_pct | cumulative_share_pct | identity_note |
|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-73422 | Lemaco Engineering Ltd | 2 | 1 | 210.29 | 7.83 | 7.83 | several name variants (DQ-13): share may be understated |
| 2 | NG-BPP-BPP-CI-1797 | M/s RCC Limited | 1 | 1 | 112.09 | 4.17 | 12 | single name |
| 3 | NG-BPP-BPP-CI-1775 | M/s Julius Berger Nig. Plc. | 1 | 1 | 88.09 | 3.28 | 15.28 | single name |
| 4 | NG-BPP-BPP-CI-452 | MESSRS KOPEK CONSTRUCTION LIMITED | 1 | 1 | 79.83 | 2.97 | 18.25 | single name |
| 5 | NG-BPP-73594 | Insil Services Ltd | 1 | 1 | 72 | 2.68 | 20.93 | single name |
| 6 | NG-BPP-BPP-CI-9059 | LLW Inter Biz LTD | 2 | 1 | 50.09 | 1.86 | 22.79 | several name variants (DQ-13): share may be understated |
| 7 | NG-BPP-47259 | VOLATIX PRODUCTS LIMITED | 1 | 1 | 44.49 | 1.66 | 24.45 | single name |
| 8 | NG-BPP-26235 | NNAMDI & SONS | 1 | 1 | 40 | 1.49 | 25.94 | single name |
| 9 | NG-BPP-BPP-CI-71 | Ric Rock Construction Nigeria Limited | 2 | 1 | 36.38 | 1.35 | 27.29 | several name variants (DQ-13): share may be understated |
| 10 | NG-BPP-BPP-CI-68 | CGC Nigeria Limited | 3 | 2 | 33.67 | 1.25 | 28.54 | several name variants (DQ-13): share may be understated |
| 11 | NG-BPP-BPP-CI-414 | ARAB CONTRACTORS O.A.O. NIGERIA LIMITED | 2 | 1 | 33.05 | 1.23 | 29.77 | several name variants (DQ-13): share may be understated |
| 12 | NG-BPP-BPP-CI-394 | SETRACO NIGERIA LIMITED | 3 | 1 | 28.53 | 1.06 | 30.84 | several name variants (DQ-13): share may be understated |
| 13 | NG-BPP-BPP-CI-422 | GILOMO ENGINEERING NIGERIA LIMITED | 1 | 1 | 27.29 | 1.02 | 31.85 | single name |
| 14 | NG-BPP-BPP-CI-4364 | M SULUM NIGERIA LIMITED | 1 | 1 | 24.75 | 0.92 | 32.77 | single name |
| 15 | NG-BPP-BPP-CI-4349 | Mellon De Company International Ltd | 2 | 2 | 22.77 | 0.85 | 33.62 | several name variants (DQ-13): share may be understated |
| 16 | NG-BPP-RC370127 | LAURMANN AND COMPANY LIMITED | 3 | 1 | 20.62 | 0.77 | 34.39 | single name |
| 17 | NG-BPP-BPP-CI-447 | MESSRS CBC GLOBAL CIVIL & BUILDING CONSTRUCTION NIGERIA LIMITED | 1 | 1 | 20.39 | 0.76 | 35.15 | single name |
| 18 | NG-BPP-RC509693 | BACKBONE CONNECTIVITY NETWORK | 4 | 1 | 20.24 | 0.75 | 35.9 | several name variants (DQ-13): share may be understated |
| 19 | NG-BPP-BPP-CI-419 | TRIACTA NIGERIA LIMITED | 5 | 1 | 20.08 | 0.75 | 36.65 | several name variants (DQ-13): share may be understated |
| 20 | NG-BPP-BPP-CI-10776 | Hakris Nigeria Limited | 1 | 1 | 19.51 | 0.73 | 37.37 | single name |

### RS4 — Concentration by procurement method (the only category-like field available)

*11 row(s), 2.6 s*

| procurement_method | eligible_awards | suppliers | value_ngn_bn | top_1_share_pct | top_5_share_pct | herfindahl_index | reliability_note |
|---|---|---|---|---|---|---|---|
| National Competitive Bidding | 7,886 | 6,177 | 1,693.23 | 6.6 | 21.5 | 141 |  |
| Selective Tendering | 3,083 | 2,540 | 453.7 | 11 | 32.3 | 279 |  |
| Emergency | 364 | 258 | 342.36 | 61.4 | 88 | 4,236 |  |
| Direct Procurement | 871 | 673 | 118.31 | 17.4 | 49.8 | 632 |  |
| (method not stated) | 106 | 106 | 31.07 | 57.5 | 81.6 | 3,669 |  |
| International Competitive Bidding | 65 | 64 | 16.77 | 8.9 | 44.5 | 667 |  |
| Request for quotation | 561 | 488 | 14.57 | 2.5 | 9.6 | 56 |  |
| Repeat Procurement | 209 | 172 | 12.12 | 8.8 | 23.3 | 218 |  |
| National Shopping | 497 | 387 | 2.7 | 8.8 | 20.5 | 153 |  |
| Sole Source | 40 | 30 | 1.8 | 25.1 | 70.1 | 1,260 |  |
| Direct Labour | 12 | 12 | 0.15 | 23.3 | 72.4 | 1,303 | small n: read with caution |

### RS5 — Concentration by procuring entity (entities with at least min_awards eligible awards)

*15 row(s), 2.5 s*

| concentration_rank | buyer_id | buyer_name | eligible_awards | suppliers | value_ngn_bn | top_1_supplier_share_pct | top_3_suppliers_share_pct | herfindahl_index | percentile_among_entities | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-161015001 | NIGERIA CHRISTIAN PILGRIM COMMISSION | 10 | 8 | 5.75 | 96.2 | 99 | 9,263 | 100 | 167 |
| 2 | NG-BPP-BPP-NOC-517019013 | ADEYEMI COLLEGE OF EDUCATION ONDO | 14 | 14 | 13 | 93.2 | 95.6 | 8,699 | 99 | 167 |
| 3 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 14 | 14 | 48.91 | 91 | 96 | 8,294 | 99 | 167 |
| 4 | NG-BPP-BPP-NOC-23 | MINISTRY OF INTERIOR | 10 | 9 | 0.28 | 90.4 | 94.4 | 8,189 | 98 | 167 |
| 5 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 277 | 252 | 66.4 | 75.4 | 76.4 | 5,696 | 98 | 167 |
| 6 | NG-BPP-BPP-NOC-228063001 | PROTOTYPE ENGINEERING DEVELOPMENT INSTITUTE , ILESHA | 29 | 25 | 1.4 | 74.6 | 83.2 | 5,622 | 97 | 167 |
| 7 | NG-BPP-BPP-NOC-31 | FEDERAL MINISTRY OF AVIATION | 18 | 10 | 19.54 | 67 | 88.4 | 4,768 | 96 | 167 |
| 8 | NG-BPP-BPP-NOC-90 | TEST MINISTRY - NOCOPO | 157 | 149 | 66.59 | 60.1 | 66 | 3,655 | 96 | 167 |
| 9 | NG-BPP-BPP-NOC-124003001 | NIGERIA IMMIGRATION SERVICE | 78 | 66 | 21.32 | 56.5 | 64.6 | 3,257 | 95 | 167 |
| 10 | NG-BPP-BPP-NOC-521027033 | FEDERAL MEDICAL CENTRE, KEBBI STATE | 37 | 27 | 6.27 | 56.3 | 72.4 | 3,343 | 95 | 167 |
| 11 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 75 | 70 | 35.53 | 54.9 | 74.8 | 3,350 | 94 | 167 |
| 12 | NG-BPP-BPP-NOC-229001001 | FEDERAL MINISTRY OF TRANSPORTATION - HQTRS | 10 | 10 | 0.91 | 53.3 | 76.5 | 3,262 | 93 | 167 |
| 13 | NG-BPP-BPP-NOC-517019010 | FEDERAL COLLEGE OF EDUCATION OBUDU | 67 | 61 | 8.09 | 51.9 | 60.3 | 2,798 | 93 | 167 |
| 14 | NG-BPP-BPP-NOC-517018039 | FEDERAL POLYTECHNIC OF OIL AND GAS, BONNY, RIVERS STATE | 13 | 8 | 0.85 | 51.3 | 70.7 | 3,046 | 92 | 167 |
| 15 | NG-BPP-BPP-NOC-521027022 | FEDERAL MEDICAL CENTRE, KATSINA | 204 | 151 | 13.24 | 49.5 | 60.9 | 2,587 | 92 | 167 |

### RS5b — Distribution of entity-level concentration (same entities as RS5)

*1 row(s), 2.4 s*

| entities_in_comparison | min_awards_threshold | p25_top_1_share_pct | median_top_1_share_pct | p75_top_1_share_pct | entities_where_one_supplier_holds_half |
|---|---|---|---|---|---|
| 167 | 10 | 13.9 | 21.2 | 29.3 | 14 |


## 02_competition.sql

*Question: How competitive are procurement processes based on available*

### RS1 — Eligible populations and headline metrics

*2 row(s), 1.4 s*

| population | eligible_tenders | median_tenderers_m_c01 | single_bidder_rate_pct_m_c02 | mean_tenderers | max_tenderers |
|---|---|---|---|---|---|
| primary (NORMAL, 1-100) | 17,469 | 2 | 43.97 | 3.22 | 90 |
| sensitivity (NORMAL + ELEVATED) | 17,482 | 2 | 43.94 | 3.53 | 897 |

### RS1b — Register entry (analytics.vw_metric_population; about 40 s because the register evaluates every view)

*2 row(s), 39.9 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-C01 (sensitivity) | Snapshot OCIDs with a tender | 17,623 | 17,482 | 99.2 |
| M-C01 / M-C02 | Snapshot OCIDs with a tender | 17,623 | 17,469 | 99.1 |

### RS2 — Participation bands (CASE classification) with cumulative share

*8 row(s), 2.0 s*

| participation_band | primary_tenders | pct_of_primary | cumulative_pct_of_primary | sensitivity_only_tenders |
|---|---|---|---|---|
| 1  single bidder | 7,681 | 43.97 | 43.97 | 0 |
| 2  two tenderers | 1,182 | 6.77 | 50.74 | 0 |
| 3  3-5 tenderers | 6,651 | 38.07 | 88.81 | 0 |
| 4  6-10 tenderers | 1,324 | 7.58 | 96.39 | 0 |
| 5  11-20 tenderers | 468 | 2.68 | 99.07 | 0 |
| 6  21-50 tenderers | 150 | 0.86 | 99.93 | 0 |
| 7  51-100 tenderers | 13 | 0.07 | 100 | 0 |
| 8  101-1,000 (ELEVATED, sensitivity only) | 0 | 0 | 100 | 13 |

### RS3 — Percentiles of tenderers (primary)

*1 row(s), 1.9 s*

| eligible_tenders | min_tenderers | p25 | median | p75 | p90 | p99 | max_tenderers |
|---|---|---|---|---|---|---|---|
| 17,469 | 1 | 1 | 2 | 4 | 6 | 20 | 90 |

### RS4 — Competition by procurement method (primary population)

*11 row(s), 2.1 s*

| procurement_method | eligible_tenders | median_tenderers | single_bidder_rate_pct | six_plus_tenderers_pct | single_bidder_gap_vs_overall_pts | reliability_note |
|---|---|---|---|---|---|---|
| National Competitive Bidding | 10,296 | 3 | 39.6 | 16.7 | -4.4 |  |
| Selective Tendering | 3,798 | 3 | 44.4 | 4.5 | 0.4 |  |
| Direct Procurement | 1,101 | 1 | 89.4 | 0.9 | 45.4 |  |
| Request for quotation | 720 | 3 | 31.3 | 0.7 | -12.7 |  |
| National Shopping | 597 | 3 | 23.6 | 1.5 | -20.4 |  |
| Emergency | 396 | 1 | 51.5 | 2.3 | 7.5 |  |
| Repeat Procurement | 281 | 1 | 87.2 | 0.4 | 43.2 |  |
| (method not stated) | 134 | 3 | 32.1 | 13.4 | -11.9 |  |
| International Competitive Bidding | 80 | 3 | 27.5 | 17.5 | -16.5 |  |
| Sole Source | 48 | 1 | 87.5 | 0 | 43.5 |  |
| Direct Labour | 18 | 1 | 77.8 | 0 | 33.8 | small n: read with caution |

### RS5 — Competition by tender status (Kene I-3: all non-null statuses kept; segmentation only)

*6 row(s), 2.2 s*

| tender_status | primary_tenders | median_tenderers | single_bidder_rate_pct | reliability_note |
|---|---|---|---|---|
| complete | 10,114 | 3 | 42.7 |  |
| active | 6,761 | 2 | 46 |  |
| planned | 506 | 2 | 42.9 |  |
| unsuccessful | 37 | 1 | 56.8 |  |
| cancelled | 32 | 2 | 43.8 |  |
| withdrawn | 19 | 5 | 26.3 | small n: read with caution |

### RS6 — Entities at the extremes of competition (primary population, DQ-19 buyer excluded)

*20 row(s), 2.4 s*

| ranking | rank_in_group | buyer_id | buyer_name | eligible_tenders | median_tenderers | single_bidder_rate_pct | single_bidder_quartile | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|
| lowest single-bidder rate | 1 | NG-BPP-BPP-NOC-517021010 | UNIVERSITY OF ABUJA | 212 | 3 | 0 | 1 | 104 |
| lowest single-bidder rate | 2 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 59 | 5 | 0 | 1 | 104 |
| lowest single-bidder rate | 3 | NG-BPP-BPP-NOC-521027038 | FEDERAL MEDICAL CENTRE, EBUTE METTA | 43 | 6 | 0 | 1 | 104 |
| lowest single-bidder rate | 4 | NG-BPP-BPP-NOC-CBAAC | CENTRE FOR BLACK AFRICAN ARTS AND CIVILISATION | 41 | 3 | 0 | 1 | 104 |
| lowest single-bidder rate | 5 | NG-BPP-BPP-NOC-215059001 | NATIONAL AGRICULTURAL LAND DEVELOPMENT AUTHORITY | 32 | 5 | 0 | 1 | 104 |
| lowest single-bidder rate | 6 | NG-BPP-BPP-NOC-124011002 | NIGERIA POLICE ACADEMY WUDIL, KANO | 31 | 3 | 0 | 1 | 104 |
| lowest single-bidder rate | 7 | NG-BPP-BPP-NOC-252045001 | OGUN/ OSUN RBDA | 364 | 3 | 1.1 | 1 | 104 |
| lowest single-bidder rate | 8 | NG-BPP-BPP-NOC-232001003 | PETROLEUM TECHNOLOGY DEVELOPMENT FUND | 89 | 3 | 2.2 | 1 | 104 |
| lowest single-bidder rate | 9 | NG-BPP-BPP-NOC-521026011 | UNIVERSITY OF MAIDUGURI TEACHING HOSPITAL | 34 | 3 | 2.9 | 1 | 104 |
| lowest single-bidder rate | 10 | NG-BPP-BPP-NOC-228073001 | ENERGY COMMISSION OF NIGERIA | 164 | 9 | 3 | 1 | 104 |
| highest single-bidder rate | 1 | NG-BPP-BPP-NOC-228039002 | NATIONAL BOARD FOR TECHNOLOGY INCUBATION | 245 | 1 | 100 | 4 | 104 |
| highest single-bidder rate | 2 | NG-BPP-BPP-NOC-521003001 | NATIONAL PRIMARY HEALTH CARE DEVELOPMENT AGENCY | 32 | 1 | 100 | 4 | 104 |
| highest single-bidder rate | 3 | NG-BPP-BPP-NOC-222013001 | ONNE OIL AND GAS FREE ZONE AUTHORITY | 71 | 1 | 98.6 | 4 | 104 |
| highest single-bidder rate | 4 | NG-BPP-BPP-NOC-252047001 | UPPER BENUE RBDA | 150 | 1 | 97.3 | 4 | 104 |
| highest single-bidder rate | 5 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 442 | 1 | 96.4 | 4 | 104 |
| highest single-bidder rate | 6 | NG-BPP-BPP-NOC-228046001 | FEDERAL INSTITUTE OF INDUSTRIAL RESEARCH -OSHODI | 90 | 1 | 95.6 | 4 | 104 |
| highest single-bidder rate | 7 | NG-BPP-BPP-NOC-111010001 | BUREAU OF PUBLIC PROCUREMENT (BPP) | 63 | 1 | 95.2 | 4 | 104 |
| highest single-bidder rate | 8 | NG-BPP-BPP-NOC-145001001 | PUBLIC COMPLAINTS COMMISSION | 60 | 1 | 95 | 4 | 104 |
| highest single-bidder rate | 9 | NG-BPP-BPP-NOC-163001002 | NIGERIA POLICE TRUST FUND | 93 | 1 | 93.5 | 4 | 104 |
| highest single-bidder rate | 10 | NG-BPP-BPP-NOC-119008001 | NIGERIAN INSTITUTE OF INTERNATIONAL AFFAIRS, LAGOS | 31 | 1 | 93.5 | 4 | 104 |


## 03_budget_to_award.sql

*Question: How does awarded value compare with recorded planning budgets, and*

### RS1 — Eligible population, totals and headline ratios

*1 row(s), 8.0 s*

| candidate_awards | eligible_ocids | eligible_pct_of_candidate | excluded_ocids | total_budget_ngn_bn | total_award_ngn_bn | net_variance_ngn_bn | aggregate_award_to_budget_ratio | median_ratio |
|---|---|---|---|---|---|---|---|---|
| 15,946 | 15,753 | 98.8 | 193 | 12,583.7 | 3,163.1 | -9,420.5 | 0.2514 | 0.9304 |

### RS1b — Register entry (analytics.vw_metric_population; about 40 s because the register evaluates every view)

*1 row(s), 42.5 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| P4-BvA | M-V01 eligible awards | 15,946 | 15,753 | 98.8 |

### RS2 — Distribution of the award-to-budget ratio (percentiles; nothing trimmed)

*1 row(s), 5.8 s*

| eligible_ocids | min_ratio | p01 | p10 | p25 | median | p75 | p90 | p99 | max_ratio |
|---|---|---|---|---|---|---|---|---|---|
| 15,753 | 0 | 0.0017 | 0.0277 | 0.2199 | 0.9304 | 1 | 1.1123 | 17.4639 | 1,710,000,000 |

### RS3 — Ratio bands (CASE classification): how many OCIDs, how much value in each

*6 row(s), 5.6 s*

| ratio_band | ocids | pct_of_ocids | budget_ngn_bn | award_ngn_bn | pct_of_award_value |
|---|---|---|---|---|---|
| 1  award below half of budget (<0.5) | 5,337 | 33.88 | 11,468.75 | 323.88 | 10.24 |
| 2  award 50-90% of budget | 2,142 | 13.6 | 293.73 | 212.99 | 6.73 |
| 3  award within 10% of budget (0.9-1.1) | 6,672 | 42.35 | 541.49 | 538.59 | 17.03 |
| 4  award 110-150% of budget | 456 | 2.89 | 100.22 | 120.68 | 3.82 |
| 5  award 1.5x-10x budget | 917 | 5.82 | 138.63 | 425.84 | 13.46 |
| 6  award above 10x budget (check units / budget entry) | 229 | 1.45 | 40.83 | 1,541.16 | 48.72 |

### RS4 — Variance by procurement method

*11 row(s), 5.7 s*

| procurement_method | eligible_ocids | budget_ngn_bn | award_ngn_bn | net_variance_ngn_bn | aggregate_ratio | median_ratio | pct_award_above_110pct_of_budget | pct_award_below_90pct_of_budget | reliability_note |
|---|---|---|---|---|---|---|---|---|---|
| National Competitive Bidding | 9,299 | 9,446.34 | 1,964.07 | -7,482.27 | 0.2079 | 0.917 | 11.3 | 48.8 |  |
| Selective Tendering | 3,387 | 827.25 | 538.93 | -288.32 | 0.6515 | 0.9832 | 10.2 | 41.2 |  |
| Direct Procurement | 974 | 627.93 | 214.94 | -412.99 | 0.3423 | 0.9407 | 7.3 | 45.1 |  |
| Request for quotation | 670 | 35.91 | 17.08 | -18.83 | 0.4757 | 0.9898 | 4.6 | 31.2 |  |
| National Shopping | 549 | 80.4 | 3.47 | -76.93 | 0.0431 | 0.1471 | 4.9 | 76.9 |  |
| Emergency | 379 | 1,231.78 | 344.64 | -887.14 | 0.2798 | 0.2313 | 7.4 | 66.8 |  |
| Repeat Procurement | 243 | 76.45 | 16.03 | -60.42 | 0.2096 | 0.9649 | 7.4 | 43.6 |  |
| (method not stated) | 123 | 124.05 | 34.23 | -89.82 | 0.2759 | 0.8627 | 10.6 | 51.2 |  |
| International Competitive Bidding | 71 | 53.09 | 27.68 | -25.41 | 0.5213 | 0.9857 | 18.3 | 43.7 |  |
| Sole Source | 44 | 80.15 | 1.88 | -78.27 | 0.0235 | 0.9781 | 9.1 | 43.2 |  |
| Direct Labour | 14 | 0.29 | 0.19 | -0.1 | 0.6639 | 0.8242 | 7.1 | 57.1 | small n: read with caution |

### RS5 — Entities with the largest net variance between awards and budgets (absolute NGN)

*15 row(s), 5.8 s*

| rank_by_abs_variance | buyer_id | buyer_name | eligible_ocids | budget_ngn_bn | award_ngn_bn | net_variance_ngn_bn | aggregate_ratio | median_ratio | cumulative_share_of_abs_variance_pct | entities_in_comparison |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,678 | 6,894.8 | 1,334.92 | -5,559.89 | 0.1936 | 0.0985 | 56 | 172 |
| 2 | NG-BPP-BPP-NOC-124002001 | NIGERIAN CORRECTIONAL SERVICE | 234 | 855.98 | 25.41 | -830.57 | 0.0297 | 0.0198 | 64.4 | 172 |
| 3 | NG-BPP-BPP-NOC-521027047 | NIGERIA CENTRE FOR DISEASE CONTROL ABUJA | 134 | 702.55 | 10.91 | -691.64 | 0.0155 | 0.0055 | 71.4 | 172 |
| 4 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 843 | 1,042.22 | 470.08 | -572.14 | 0.451 | 0.2479 | 77.1 | 172 |
| 5 | NG-BPP-BPP-NOC-232007001 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 624 | 379.44 | 77.53 | -301.91 | 0.2043 | 0.8841 | 80.2 | 172 |
| 6 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 423 | 315.39 | 28.18 | -287.2 | 0.0894 | 0.0607 | 83.1 | 172 |
| 7 | NG-BPP-BPP-NOC-252001001 | FEDERAL MINISTRY OF WATER RESOURCES - HQTRS | 393 | 280.74 | 21.11 | -259.64 | 0.0752 | 0.0205 | 85.7 | 172 |
| 8 | NG-BPP-BPP-NOC-220007049 | FEDERAL INLAND REVENUE SERVICE | 791 | 297.54 | 124.36 | -173.18 | 0.4179 | 0.9899 | 87.4 | 172 |
| 9 | NG-BPP-BPP-NOC-116001001 | FEDERAL MINISTRY OF DEFENCE - MAIN MOD | 289 | 127.68 | 20.85 | -106.83 | 0.1633 | 0.2193 | 88.5 | 172 |
| 10 | NG-BPP-BPP-NOC-215002001 | FEDERAL COLLEGE OF PRODUCE INSPECTION AND STORED PRODUCTS TECHNOLOGY, KANO | 66 | 103.97 | 4.33 | -99.64 | 0.0416 | 0.9985 | 89.5 | 172 |
| 11 | NG-BPP-BPP-NOC-222001002 | CORPORATE AFFAIRS COMMISSION | 251 | 99.43 | 6.12 | -93.31 | 0.0616 | 0.0465 | 90.4 | 172 |
| 12 | NG-BPP-BPP-NOC-553001001 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 173 | 129.1 | 42.66 | -86.44 | 0.3304 | 1 | 91.3 | 172 |
| 13 | NG-BPP-BPP-NOC-163001002 | NIGERIA POLICE TRUST FUND | 89 | 99.11 | 14.09 | -85.02 | 0.1422 | 1 | 92.2 | 172 |
| 14 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 58 | 4.03 | 86.17 | 82.14 | 21.3731 | 1 | 93 | 172 |
| 15 | NG-BPP-BPP-NOC-90 | TEST MINISTRY - NOCOPO | 179 | 149.13 | 71.63 | -77.5 | 0.4803 | 0.99 | 93.8 | 172 |

### RS6 — Entities whose typical process departs most from budget (median ratio), same comparison set

*15 row(s), 5.6 s*

| rank_by_median_departure | buyer_id | buyer_name | eligible_ocids | median_ratio | pct_ocids_within_10pct_of_budget | alignment_quartile | entities_in_comparison |
|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-521027047 | NIGERIA CENTRE FOR DISEASE CONTROL ABUJA | 134 | 0.0055 | 0.7 | 1 | 172 |
| 2 | NG-BPP-BPP-NOC-124002001 | NIGERIAN CORRECTIONAL SERVICE | 234 | 0.0198 | 0.4 | 1 | 172 |
| 3 | NG-BPP-BPP-NOC-252001001 | FEDERAL MINISTRY OF WATER RESOURCES - HQTRS | 393 | 0.0205 | 4.6 | 1 | 172 |
| 4 | NG-BPP-BPP-NOC-222001002 | CORPORATE AFFAIRS COMMISSION | 251 | 0.0465 | 10.4 | 1 | 172 |
| 5 | NG-BPP-BPP-NOC-232001001 | MINSITRY OF ENERGY (PETROLEUM RESOURCES) HQTRS | 23 | 0.0487 | 0 | 1 | 172 |
| 6 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 423 | 0.0607 | 10.9 | 1 | 172 |
| 7 | NG-BPP-BPP-NOC-222013001 | ONNE OIL AND GAS FREE ZONE AUTHORITY | 69 | 0.0613 | 8.7 | 1 | 172 |
| 8 | NG-BPP-BPP-NOC-124004001 | NIGERIA SECURITY AND CIVIL DEFENCE CORPS | 115 | 0.0798 | 0.9 | 1 | 172 |
| 9 | NG-BPP-BPP-NOC-611001002 | COURT OF APPEAL | 17 | 0.0829 | 0 | 1 | 172 |
| 10 | NG-BPP-BPP-NOC-119009001 | NIGERIANS IN DIASPORA COMMISSION | 12 | 0.0928 | 16.7 | 1 | 172 |
| 11 | NG-BPP-BPP-NOC-222001001 | FEDERAL MINISTRY OF INDUSTRY, TRADE AND INVESTMENT - HQTRS | 22 | 0.0973 | 27.3 | 2 | 172 |
| 12 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,678 | 0.0985 | 11.9 | 1 | 172 |
| 13 | NG-BPP-BPP-NOC-517021025 | NATIONAL MATHEMATICAL CENTRE, SHEDA | 68 | 0.1096 | 0 | 1 | 172 |
| 14 | NG-BPP-BPP-NOC-31 | FEDERAL MINISTRY OF AVIATION | 20 | 0.1414 | 0 | 1 | 172 |
| 15 | NG-BPP-BPP-NOC-229031006 | ACCIDENT INVESTIGATION BUREAU | 170 | 0.1515 | 7.1 | 1 | 172 |

### RS7 — Double-count check: is any planning budget line compared against more than one OCID?

*1 row(s), 6.1 s*

| budget_project_ids | ids_used_by_several_ocids | summed_budget_ngn_bn | budget_counted_once_ngn_bn | reading |
|---|---|---|---|---|
| 15,753 | 0 | 12,583.7 | 12,583.7 | no budget line is repeated across OCIDs: totals are not inflated by sharing |


## 04_procurement_cycle_timing.sql

*Question: What can valid tender, award and contract dates tell us about*

### RS1 — Eligible population sizes and medians (headline timing metrics)

*3 row(s), 7.0 s*

| measure | eligible_n | median_days |
|---|---|---|
| M-E01 tender open duration (days) | 9,180 | 28 |
| M-E02 award lag, tender start to award (days) | 7,569 | 94 |
| P5-SIG signature lag, award to signing (days) | 12,138 | 5 |

### RS1b — Coverage: candidate population, eligible count and eligible share (analytics.vw_metric_population; about 40 s)

*3 row(s), 43.6 s*

| metric_id | metric_name | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|---|
| M-E01 | Median tender duration (days) | Snapshot OCIDs with a tender | 17,623 | 9,180 | 52.1 |
| M-E02 | Median award lag (days) | Snapshot OCIDs with a tender and an award | 16,715 | 7,569 | 45.3 |
| P5-SIG | Contract signature lag (days) | Snapshot contracts | 16,392 | 12,138 | 74 |

### RS2 — Distribution of each interval, with counts of unusually long intervals (kept, not removed)

*3 row(s), 1.7 s*

| measure | eligible_n | min_days | p25 | median | p75 | p90 | p99 | max_days | mean_days | same_day | over_1_year | over_1_year_pct |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| M-E01 tender open duration | 9,180 | 1 | 14 | 28 | 43 | 64 | 336 | 3,696 | 40.5 | 0 | 68 | 0.74 |
| M-E02 award lag | 7,569 | 0 | 42 | 94 | 150 | 266 | 574 | 3,756 | 124 | 96 | 297 | 3.92 |
| P5-SIG signature lag | 12,138 | 0 | 0 | 5 | 27 | 62 | 377 | 7,310 | 28.1 | 3,853 | 158 | 1.3 |

### RS3 — Duration bands (CASE classification)

*18 row(s), 1.6 s*

| measure | duration_band | processes | pct_of_measure | cumulative_pct |
|---|---|---|---|---|
| M-E01 tender open duration | 1  up to 7 days | 1,117 | 12.17 | 12.17 |
| M-E01 tender open duration | 2  8-30 days | 3,825 | 41.67 | 53.83 |
| M-E01 tender open duration | 3  31-90 days | 3,696 | 40.26 | 94.1 |
| M-E01 tender open duration | 4  91-180 days | 370 | 4.03 | 98.13 |
| M-E01 tender open duration | 5  181-365 days | 104 | 1.13 | 99.26 |
| M-E01 tender open duration | 6  over 1 year | 68 | 0.74 | 100 |
| M-E02 award lag | 1  up to 7 days | 267 | 3.53 | 3.53 |
| M-E02 award lag | 2  8-30 days | 1,206 | 15.93 | 19.46 |
| M-E02 award lag | 3  31-90 days | 2,005 | 26.49 | 45.95 |
| M-E02 award lag | 4  91-180 days | 2,665 | 35.21 | 81.16 |
| M-E02 award lag | 5  181-365 days | 1,129 | 14.92 | 96.08 |
| M-E02 award lag | 6  over 1 year | 297 | 3.92 | 100 |
| P5-SIG signature lag | 1  up to 7 days | 6,919 | 57 | 57 |
| P5-SIG signature lag | 2  8-30 days | 2,464 | 20.3 | 77.3 |
| P5-SIG signature lag | 3  31-90 days | 2,257 | 18.59 | 95.9 |
| P5-SIG signature lag | 4  91-180 days | 251 | 2.07 | 97.97 |
| P5-SIG signature lag | 5  181-365 days | 89 | 0.73 | 98.7 |
| P5-SIG signature lag | 6  over 1 year | 158 | 1.3 | 100 |

### RS4 — Timing by procurement method (eligible populations only; n shown for each measure)

*11 row(s), 4.8 s*

| procurement_method | tender_duration_n | median_tender_duration_days | award_lag_n | median_award_lag_days | reliability_note |
|---|---|---|---|---|---|
| National Competitive Bidding | 6,108 | 42 | 4,946 | 115 |  |
| Selective Tendering | 1,628 | 21 | 1,348 | 43 |  |
| National Shopping | 360 | 7 | 319 | 14 |  |
| Emergency | 295 | 4 | 279 | 9 |  |
| Request for quotation | 290 | 14 | 250 | 28 |  |
| Direct Procurement | 274 | 21 | 243 | 112 |  |
| Repeat Procurement | 87 | 47 | 75 | 62 |  |
| (method not stated) | 65 | 25 | 54 | 97.5 |  |
| International Competitive Bidding | 59 | 30 | 44 | 139.5 |  |
| Sole Source | 9 | 13 | 7 | 18 | small n in at least one measure: read with caution |
| Direct Labour | 5 | 29 | 4 | 58.5 | small n in at least one measure: read with caution |

### RS5 — Tender open duration by year of tender start, with year-on-year change in the median

*15 row(s), 2.2 s*

| tender_start_year | eligible_n | median_days | change_vs_previous_year_days | reliability_note |
|---|---|---|---|---|
| 2010 | 4 | 41 |  | small n: read with caution |
| 2011 | 5 | 42 | 1 | small n: read with caution |
| 2013 | 1 | 42 |  | small n: read with caution |
| 2014 | 1 | 31 | -11 | small n: read with caution |
| 2015 | 4 | 46.5 | 15.5 | small n: read with caution |
| 2016 | 31 | 42 | -4.5 |  |
| 2017 | 485 | 50 | 8 |  |
| 2018 | 830 | 43 | -7 |  |
| 2019 | 1,025 | 42 | -1 |  |
| 2020 | 1,459 | 18 | -24 |  |
| 2021 | 1,582 | 42 | 24 |  |
| 2022 | 1,773 | 28 | -14 |  |
| 2023 | 1,242 | 28 | 0 |  |
| 2024 | 702 | 28 | 0 |  |
| 2025 | 36 | 28 | 0 |  |

### RS6 — Award lag by year of award date, with year-on-year change in the median

*12 row(s), 2.4 s*

| award_year | eligible_n | median_days | change_vs_previous_year_days | reliability_note |
|---|---|---|---|---|
| 2010 | 1 | 46 |  | small n: read with caution |
| 2011 | 3 | 133 | 87 | small n: read with caution |
| 2016 | 11 | 59 |  | small n: read with caution |
| 2017 | 142 | 86 | 27 |  |
| 2018 | 551 | 104 | 18 |  |
| 2019 | 1,263 | 137 | 33 |  |
| 2020 | 1,430 | 41 | -96 |  |
| 2021 | 977 | 92 | 51 |  |
| 2022 | 1,280 | 113 | 21 |  |
| 2023 | 1,254 | 101.5 | -11.5 |  |
| 2024 | 625 | 98 | -3.5 |  |
| 2025 | 32 | 61.5 | -36.5 |  |


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

*1 row(s), 11.9 s*

| entities | processes_in_scope | entities_with_budget_lines | entities_with_competition_data | entities_competition_n_30_plus | entities_with_awards | entities_award_n_10_plus | entities_with_contracts | entities_contract_n_20_plus | total_award_value_ngn_bn | total_planned_budget_ngn_bn |
|---|---|---|---|---|---|---|---|---|---|---|
| 666 | 98,840 | 665 | 281 | 104 | 260 | 174 | 258 | 124 | 3,361.5 | 93,809.2 |

### RS1b — Register entry (analytics.vw_metric_population; about 40 s because the register evaluates every view)

*1 row(s), 40.3 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| ENTITY | Buyer IDs (core.dim_buyer) | 667 | 666 | 99.9 |

### RS2 — How much activity sits with the largest entities (window functions: rank and cumulative share)

*6 row(s), 7.3 s*

| largest_entities | pct_of_award_value | pct_of_processes | pct_of_planned_budget |
|---|---|---|---|
| 1 | 39.7 | 5.2 | 27.5 |
| 5 | 65.2 | 17.4 | 59.4 |
| 10 | 75.3 | 26.8 | 72.1 |
| 20 | 83.5 | 39.1 | 80.8 |
| 50 | 92.6 | 56.9 | 90.3 |
| 100 | 97.6 | 71.7 | 95.5 |

### RS3 — Top 15 entities by awarded value, with their rank on each activity measure

*15 row(s), 7.4 s*

| rank_award_value | buyer_id | buyer_name | award_value_ngn_bn | cumulative_share_of_award_value_pct | award_n | process_count | planned_budget_ngn_bn | rank_processes | rank_awards | rank_budget |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,335.1 | 39.7 | 1,682 | 4,626 | 25,785.7 | 2 | 1 | 1 |
| 2 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 470.1 | 53.7 | 844 | 5,148 | 14,540.9 | 1 | 2 | 2 |
| 3 | NG-BPP-BPP-NOC-521027034 | FEDERAL MEDICAL CENTRE, TARABA STATE | 175.8 | 58.9 | 10 | 28 | 6 | 378 | 168 | 283 |
| 4 | NG-BPP-BPP-NOC-220007049 | FEDERAL INLAND REVENUE SERVICE | 125 | 62.7 | 799 | 2,470 | 634.8 | 4 | 3 | 18 |
| 5 | NG-BPP-BPP-NOC-252041001 | HADEJIA-JAMAÄ»ARE RBDA | 86.2 | 65.2 | 58 | 1,012 | 71.2 | 17 | 58 | 87 |
| 6 | NG-BPP-BPP-NOC-232007001 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 77.9 | 67.5 | 627 | 1,526 | 1,158.6 | 12 | 5 | 12 |
| 7 | NG-BPP-BPP-NOC-90 | TEST MINISTRY - NOCOPO | 72 | 69.7 | 183 | 412 | 529.7 | 51 | 21 | 23 |
| 8 | NG-BPP-BPP-NOC-539001003 | BORDER COMMUNITIES DEVELOPMENT AGENCY | 71.6 | 71.8 | 744 | 2,513 | 182.8 | 3 | 4 | 44 |
| 9 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 66.5 | 73.8 | 281 | 2,409 | 7,534.1 | 5 | 11 | 3 |
| 10 | NG-BPP-BPP-NOC-521026001 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 50 | 75.3 | 21 | 73 | 9.3 | 244 | 117 | 235 |
| 11 | NG-BPP-BPP-NOC-553001001 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 43 | 76.6 | 178 | 294 | 662.1 | 74 | 22 | 17 |
| 12 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 36.7 | 77.6 | 83 | 309 | 118.4 | 70 | 44 | 64 |
| 13 | NG-BPP-BPP-NOC-227004001 | NATIONAL PRODUCTIVITY CENTRE | 29.9 | 78.5 | 204 | 1,930 | 177.5 | 7 | 18 | 48 |
| 14 | NG-BPP-BPP-NOC-123031011 | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | 29 | 79.4 | 106 | 183 | 9.8 | 122 | 35 | 233 |
| 15 | NG-BPP-BPP-NOC-517001001 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 28.6 | 80.3 | 431 | 1,303 | 2,064.4 | 15 | 6 | 10 |

### RS4 — KPI profile of the top 15 entities by awarded value, each KPI beside its own n and percentile position

*15 row(s), 11.3 s*

| rank_award_value | buyer_name | tender_reach_pct | reach_pctile | competition_n | median_tenderers | tenderers_pctile | single_bidder_pct | single_bidder_pctile | award_n | top_supplier_share_pct | top_supplier_pctile | contract_n | implementation_coverage_pct | implementation_pctile |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 36.8 | 80 | 1,635 | 4 | 83 | 3.7 | 10 | 1,682 | 11.1 | 17 | 1,677 | 21.6 | 2 |
| 2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 18.7 | 67 | 950 | 3 | 56 | 37.8 | 43 | 844 | 45.4 | 88 | 844 | 79 | 7 |
| 3 | FEDERAL MEDICAL CENTRE, TARABA STATE |  |  | 10 |  |  |  |  | 10 | 49.1 | 90 | 8 |  |  |
| 4 | FEDERAL INLAND REVENUE SERVICE | 37.5 | 80 | 922 | 1 | 0 | 69.5 | 68 | 799 | 18.3 | 42 | 910 | 98.6 | 43 |
| 5 | HADEJIA-JAMAÄ»ARE RBDA | 5.8 | 49 | 59 | 5 | 91 | 0 | 0 | 58 | 29 | 72 | 57 | 98.3 | 39 |
| 6 | NIGERIA CONTENT DEVELOPMENT AND MONITORING BOARD | 41.7 | 83 | 636 | 1 | 0 | 57.6 | 60 | 627 | 7.8 | 7 | 622 | 99.2 | 54 |
| 7 | TEST MINISTRY - NOCOPO | 52.9 | 91 | 216 | 2 | 49 | 38 | 44 | 183 | 60.1 | 95 | 171 | 95.9 | 28 |
| 8 | BORDER COMMUNITIES DEVELOPMENT AGENCY | 30.8 | 76 | 765 | 3 | 56 | 17.3 | 35 | 744 | 8.2 | 9 | 737 | 98.6 | 47 |
| 9 | FEDERAL MINISTRY OF AGRICULTURE | 12.2 | 59 | 294 | 1 | 0 | 80.3 | 78 | 281 | 75.4 | 97 | 284 | 84.2 | 11 |
| 10 | UNIVERSITY COLLEGE HOSPITAL IBADAN | 28.8 | 75 | 21 |  |  |  |  | 21 | 91 | 98 | 21 | 85.7 | 12 |
| 11 | MINISTRY OF HUMANITARIAN AFFAIRS, DISASTER MANAGEMENT AND SOCIAL DEVELOPMENT HQRS | 69.7 | 97 | 203 | 5 | 91 | 7.4 | 18 | 178 | 28.7 | 70 | 205 | 100 | 59 |
| 12 | NATIONAL INLAND WATERWAYS AUTHORITY | 35 | 79 | 108 | 11 | 100 | 5.6 | 15 | 83 | 54.9 | 94 | 83 | 4.8 | 1 |
| 13 | NATIONAL PRODUCTIVITY CENTRE | 13 | 60 | 249 | 2 | 49 | 40.6 | 49 | 204 | 29.6 | 73 | 196 | 93.4 | 21 |
| 14 | NATIONAL INSTITUTE FOR CULTURE ORIENTATION | 59 | 93 | 108 | 4 | 83 | 5.6 | 15 | 106 | 45 | 87 | 108 | 99.1 | 50 |
| 15 | FEDERAL MINISTRY OF EDUCATION - HQTRS | 34.4 | 78 | 442 | 1 | 0 | 96.4 | 96 | 431 | 46.6 | 90 | 433 | 98.6 | 46 |

### RS5 — Spread of each KPI across entities that meet the minimum n (the yardstick for RS4)

*5 row(s), 20.9 s*

| kpi | entities_compared | p10 | p25 | median | p75 | p90 |
|---|---|---|---|---|---|---|
| tender reach rate | 374 | 0 | 0 | 0.065 | 0.283 | 0.52 |
| median tenderers | 104 | 1 | 1 | 2 | 3 | 4 |
| single-bidder rate | 104 | 0.037 | 0.097 | 0.415 | 0.778 | 0.931 |
| top-supplier value share | 174 | 0.082 | 0.141 | 0.222 | 0.316 | 0.484 |
| implementation coverage rate | 124 | 0.834 | 0.951 | 0.99 | 1 | 1 |

### RS6 — Do larger entities differ? KPI medians by quartile of awarded value (entities with awards)

*4 row(s), 7.7 s*

| value_quartile | entities | award_value_ngn_bn | pct_of_award_value | entities_with_competition_n | median_single_bidder_pct | entities_with_contract_n | median_implementation_coverage_pct | reliability_note |
|---|---|---|---|---|---|---|---|---|
| 1 | 65 | 3,186.2 | 94.8 | 57 | 40.6 | 59 | 98.8 |  |
| 2 | 65 | 135.6 | 4 | 39 | 49.3 | 51 | 99.6 |  |
| 3 | 65 | 34.3 | 1 | 5 | 85 | 11 | 97.8 | fewer than 10 entities in a KPI: read with caution |
| 4 | 65 | 5.3 | 0.2 | 3 | 33.3 | 3 | 100 | fewer than 10 entities in a KPI: read with caution |


## 06_implementation_coverage.sql

*Question: What proportion of contracts has usable implementation/payment*

### RS1 — M-I01 headline: eligible population and coverage rate

*1 row(s), 1.7 s*

| eligible_contracts | contracts_with_implementation_data | coverage_rate_pct_m_i01 | contracts_without_implementation_data |
|---|---|---|---|
| 16,392 | 14,304 | 87.26 | 2,088 |

### RS1b — Register entries (analytics.vw_metric_population; about 40 s because the register evaluates every view)

*2 row(s), 39.7 s*

| metric_id | candidate_population | candidate_count | eligible_count | eligible_pct |
|---|---|---|---|---|
| M-E03 | All OCIDs (no exclusions by spec) | 98,866 | 98,866 | 100 |
| M-I01 | Snapshot contracts (no exclusions by spec) | 16,392 | 16,392 | 100 |

### RS2 — What kind of implementation data exists (CASE classification)

*3 row(s), 2.1 s*

| implementation_data_type | contracts | pct_of_contracts | transactions | implementation_milestones |
|---|---|---|---|---|
| 1  transactions and milestones | 12,958 | 79.05 | 13,065 | 24,370 |
| 2  milestones only | 1,346 | 8.21 | 0 | 2,582 |
| 4  no implementation data | 2,088 | 12.74 | 0 | 0 |

### RS3 — Coverage by contract status

*4 row(s), 1.7 s*

| contract_status | contracts | with_implementation_data | coverage_rate_pct | reliability_note |
|---|---|---|---|---|
| active | 15,822 | 13,771 | 87.04 |  |
| cancelled | 339 | 335 | 98.82 |  |
| pending | 122 | 91 | 74.59 |  |
| terminated | 109 | 107 | 98.17 |  |

### RS4 — Distribution of coverage across entities (entities with at least min_contracts contracts)

*5 row(s), 1.9 s*

| entity_coverage_band | entities | pct_of_entities | contracts_held | pct_of_contracts | min_contracts_threshold |
|---|---|---|---|---|---|
| 1  full coverage (100%) | 52 | 41.9 | 3,090 | 20.1 | 20 |
| 2  90% to under 100% | 48 | 38.7 | 8,496 | 55.2 | 20 |
| 3  50% to under 90% | 18 | 14.5 | 1,904 | 12.4 | 20 |
| 4  under 50% | 5 | 4 | 1,887 | 12.3 | 20 |
| 5  none reported (0%) | 1 | 0.8 | 20 | 0.1 | 20 |

### RS5 — Entities with the lowest coverage (reporting gaps; not a performance ranking)

*15 row(s), 1.9 s*

| rank_lowest_coverage | buyer_id | buyer_name | contracts | with_implementation_data | coverage_rate_pct | percentile_among_entities | entities_in_comparison |
|---|---|---|---|---|---|---|---|
| 1 | NG-BPP-BPP-NOC-535013001 | FORESTRY RESEARCH INSTITUTE OF IBADAN | 20 | 0 | 0 | 0 | 124 |
| 2 | NG-BPP-BPP-NOC-229004001 | NATIONAL INLAND WATERWAYS AUTHORITY | 83 | 4 | 4.8 | 1 | 124 |
| 3 | NG-BPP-BPP-NOC-231001001 | FEDERAL MINISTRY OF WORKS & HOUSING - HQTRS | 1,677 | 362 | 21.6 | 2 | 124 |
| 4 | NG-BPP-BPP-NOC-517019010 | FEDERAL COLLEGE OF EDUCATION OBUDU | 77 | 21 | 27.3 | 2 | 124 |
| 5 | NG-BPP-BPP-NOC-517024001 | NATIONAL OPEN UNIVERSITY | 21 | 8 | 38.1 | 3 | 124 |
| 6 | NG-BPP-BPP-NOC-521027029 | FEDERAL TEACHING HOSPITAL, ABAKALIKI | 29 | 12 | 41.4 | 4 | 124 |
| 7 | NG-BPP-BPP-NOC-521026008 | JOS UNIVERSITY TEACHING HOSPITAL | 29 | 15 | 51.7 | 5 | 124 |
| 8 | NG-BPP-BPP-NOC-228050001 | NIGERIA INSTITUTE OF LEATHER AND SCIENCE TECHNOLOGY (NILEST) HQTRS | 57 | 37 | 64.9 | 6 | 124 |
| 9 | NG-BPP-BPP-NOC-228063001 | PROTOTYPE ENGINEERING DEVELOPMENT INSTITUTE , ILESHA | 37 | 28 | 75.7 | 7 | 124 |
| 10 | NG-BPP-BPP-NOC-2 | FEDERAL CAPITAL TERRITORY ADMINISTRATION | 844 | 667 | 79 | 7 | 124 |
| 11 | NG-BPP-BPP-NOC-517021030 | FEDERAL UNIVERSITY OTUOKE | 24 | 19 | 79.2 | 8 | 124 |
| 12 | NG-BPP-BPP-NOC-517021006 | UNIVERSITY OF BENIN | 23 | 19 | 82.6 | 9 | 124 |
| 13 | NG-BPP-BPP-NOC-513001001 | FEDERAL MINISTRY OF YOUTH & SPORTS DEVELOPMENT - HQTRS | 89 | 74 | 83.1 | 10 | 124 |
| 14 | NG-BPP-BPP-NOC-535015001 | NATIONAL OIL SPILL DETECTION AND RESPONSE AGENCY | 50 | 42 | 84 | 11 | 124 |
| 15 | NG-BPP-BPP-NOC-3 | FEDERAL MINISTRY OF AGRICULTURE | 284 | 239 | 84.2 | 11 | 124 |

### RS6 — Lifecycle funnel (M-E03): how far did processes get in what was published?

*5 row(s), 2.6 s*

| stage_order | stage | ocids_whose_last_published_stage_is_this | ocids_reaching_stage_or_beyond | pct_of_all_ocids | conversion_from_previous_stage_pct |
|---|---|---|---|---|---|
| 1 | planning | 81,243 | 98,866 | 100 |  |
| 2 | tender | 908 | 17,623 | 17.83 | 17.83 |
| 3 | award | 323 | 16,715 | 16.91 | 94.85 |
| 4 | contract | 2,079 | 16,392 | 16.58 | 98.07 |
| 5 | implementation | 14,313 | 14,313 | 14.48 | 87.32 |


## 07_data_quality_impact.sql

*Question: Which data-quality issues could materially affect the*

### RS1 — Exclusions by metric: candidate, eligible, and how the excluded records divide by cause

*9 row(s), 35.7 s*

| metric_order | metric_id | metric_name | candidate_records | eligible_records | eligible_pct | excluded_records | lost_to_one_dq_issue_only | lost_to_non_dq_rule_only | lost_to_two_or_more_reasons | reconciles_candidate_minus_eligible |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | M-P01 | Total planned budget by entity | 97,749 | 97,196 | 99.4 | 553 | 534 | 0 | 19 | yes |
| 2 | M-C01 / M-C02 | Median tenderers; single-bidder rate (primary) | 17,623 | 17,469 | 99.1 | 154 | 78 | 76 | 0 | yes |
| 3 | M-V01 | Median award value | 16,715 | 15,946 | 95.4 | 769 | 244 | 505 | 20 | yes |
| 4 | M-S01 | Top-supplier award value concentration | 15,946 | 13,694 | 85.9 | 2,252 | 2,252 | 0 | 0 | yes |
| 5 | P4-BvA | Budget-to-award comparison | 15,946 | 15,753 | 98.8 | 193 | 62 | 131 | 0 | yes |
| 6 | M-E01 | Median tender duration (days) | 17,623 | 9,180 | 52.1 | 8,443 | 30 | 8,413 | 0 | yes |
| 7 | M-E02 | Median award lag (days) | 16,715 | 7,569 | 45.3 | 9,146 | 189 | 8,857 | 100 | yes |
| 8 | P5-SIG | Contract signature lag (days) | 16,392 | 12,138 | 74 | 4,254 | 845 | 3,310 | 99 | yes |
| 11 | ENTITY | Procuring-entity benchmark | 667 | 666 | 99.9 | 1 | 1 | 0 | 0 | yes |

### RS2 — Issue-by-metric matrix: size of each issue's footprint, value at stake, materiality

*25 row(s), 44.6 s*

| metric_id | dq_ref | dq_issue | impact_type | treatment | candidate_records | records_with_issue | pct_of_candidate | records_lost_only_to_issue | affected_value_ngn_bn | value_pct_of_candidate | materiality | rank_within_metric | note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ALL | DQ-01 | Repeated OCIDs (multi-release processes) | DISCLOSED | RETAIN | 98,866 | 6,280 | 6.35 |  |  |  | MODERATE | 1 | Not excluded. The process snapshot (Phase 4 v1.1) takes the latest release per section, so values are not double-counted. |
| M-P01 | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 97,749 | 495 | 0.51 | 495 | 0 | 0 | LOW | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| M-P01 | DQ-06 | Extreme budget (>= NGN 1 trillion) | EXCLUDES | EXCLUDE_FROM_METRIC | 97,749 | 32 | 0.03 | 32 | 96,441.9 | 50.7 | HIGH | 2 | Retained in core and flagged; value would dominate any total or ratio. |
| M-P01 | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 97,749 | 26 | 0.03 | 7 | 18.6 | 0 | LOW | 3 | Excluded from per-entity measures; kept in overall process counts. |
| M-P01 | DQ-18 | Release with no parties array | EXCLUDES | EXCLUDE_FROM_METRIC | 97,749 | 19 | 0.02 | 0 | 14 | 0 | LOW | 4 | Buyer cannot be derived, so the line is left out of buyer-level budget totals. |
| M-C01 / M-C02 | DQ-05 | Anomalous tenderer count (>1,000) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,623 | 65 | 0.37 | 65 |  |  | LOW | 1 | Excluded from primary and sensitivity populations. |
| M-C01 / M-C02 | DQ-04 | Elevated tenderer count (101-1,000) | EXCLUDES_FROM_PRIMARY | FLAG | 17,623 | 13 | 0.07 | 13 |  |  | LOW | 2 | Excluded from the primary result; kept in the sensitivity population (M-C01). |
| M-V01 | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 16,715 | 263 | 1.57 | 243 | 0 | 0 | MODERATE | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| M-V01 | DQ-07 | Extreme award value (FCTA NGN 1.004T) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,715 | 1 | 0.01 | 1 | 1,004.2 | 22.9 | HIGH | 2 | Retained in core and flagged; value would dominate any total or median. |
| M-S01 | DQ-13 | Supplier ID with several name variants | DISCLOSED | RETAIN | 13,694 | 4,194 | 30.63 |  | 894.5 | 33.3 | HIGH | 1 | Not merged. Supplier concentration is a lower bound where one real supplier carries several IDs (DQ-14, DQ-15). |
| M-S01 | DQ-14 | Incomplete supplier ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 15,946 | 2,252 | 14.12 | 2,252 | 675.8 | 20.1 | HIGH | 2 | Supplier identity cannot be resolved, so the award is left out of supplier concentration. State this with every M-S01 figure. |
| P4-BvA | DQ-16 | Zero monetary value | EXCLUDES | EXCLUDE_FROM_METRIC | 15,946 | 59 | 0.37 | 59 | 15.9 | 0.5 | LOW | 1 | Zero is treated as unusable for value metrics, not as a real amount of nothing. |
| P4-BvA | C-06 | Several unrelated budget lines on one OCID (MULTI_PROJECT) | EXCLUDES | EXCLUDE_FROM_METRIC | 15,946 | 3 | 0.02 | 3 | 0.3 | 0 | LOW | 2 | Kene I-2: no rule says which budget line an award answers, so the OCID is left out of budget-to-award. |
| M-E01 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,623 | 24 | 0.14 | 24 |  |  | LOW | 1 | Excluded from the timing metric that needs the date. |
| M-E01 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 17,623 | 6 | 0.03 | 6 |  |  | LOW | 2 | Excluded from the timing metric that needs the date. |
| M-E02 | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,715 | 141 | 0.84 | 141 |  |  | LOW | 1 | No DQ number. Negative durations are excluded, not corrected (Kene decision, Phase 7). |
| M-E02 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,715 | 138 | 0.83 | 43 |  |  | LOW | 2 | Excluded from the timing metric that needs the date. |
| M-E02 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,715 | 10 | 0.06 | 5 |  |  | LOW | 3 | Excluded from the timing metric that needs the date. |
| P5-SIG | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,392 | 756 | 4.61 | 756 |  |  | MODERATE | 1 | No DQ number. Negative durations are excluded, not corrected (Kene decision, Phase 7). |
| P5-SIG | DQ-08 | Placeholder date (2001-01-01) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,392 | 181 | 1.1 | 83 |  |  | MODERATE | 2 | Excluded from the timing metric that needs the date. |
| P5-SIG | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDES | EXCLUDE_FROM_METRIC | 16,392 | 7 | 0.04 | 6 |  |  | LOW | 3 | Excluded from the timing metric that needs the date. |
| M-E03 | DQ-02 | Planning-only processes | DISCLOSED | RETAIN | 98,866 | 81,243 | 82.17 |  |  |  | HIGH | 1 | Not excluded. Most processes were published only at planning stage, so later-stage metrics describe a small share of all OCIDs. |
| M-I01 | DQ-11 | Implementation transaction dates absent | DISCLOSED | RETAIN | 16,392 | 12,958 | 79.05 |  |  |  | HIGH | 1 | Transactions are used for presence only; payment timing cannot be measured. |
| M-I01 | DQ-12 | Implementation transaction value semantics unclear | DISCLOSED | RETAIN | 16,392 | 12,958 | 79.05 |  |  |  | HIGH | 1 | Transaction values are not summed; the field meaning is unresolved. |
| ENTITY | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDES | EXCLUDE_FROM_METRIC | 667 | 1 | 0.15 | 1 |  |  | LOW | 1 | Excluded from per-entity measures; kept in overall process counts. |

### RS3 — Which issues matter most across metrics (how many metrics each touches materially)

*17 row(s), 44.4 s*

| issue_rank | dq_ref | dq_issue | treatment | metrics_touched | metrics_high | metrics_moderate | metrics_affected |
|---|---|---|---|---|---|---|---|
| 1 | DQ-02 | Planning-only processes | RETAIN | 1 | 1 | 0 | M-E03 (HIGH, 82.2% of records or value) |
| 1 | DQ-06 | Extreme budget (>= NGN 1 trillion) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-P01 (HIGH, 50.7% of records or value) |
| 1 | DQ-07 | Extreme award value (FCTA NGN 1.004T) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-V01 (HIGH, 22.9% of records or value) |
| 1 | DQ-11 | Implementation transaction dates absent | RETAIN | 1 | 1 | 0 | M-I01 (HIGH, 79.1% of records or value) |
| 1 | DQ-12 | Implementation transaction value semantics unclear | RETAIN | 1 | 1 | 0 | M-I01 (HIGH, 79.1% of records or value) |
| 1 | DQ-13 | Supplier ID with several name variants | RETAIN | 1 | 1 | 0 | M-S01 (HIGH, 33.3% of records or value) |
| 1 | DQ-14 | Incomplete supplier ID (bare NG-BPP-) | EXCLUDE_FROM_METRIC | 1 | 1 | 0 | M-S01 (HIGH, 20.1% of records or value) |
| 8 | DATE-ORDER | Date chronology conflict (end before start) | EXCLUDE_FROM_METRIC | 2 | 0 | 1 | M-E02 (LOW, 0.8% of records or value); P5-SIG (MODERATE, 4.6% of records or value) |
| 8 | DQ-01 | Repeated OCIDs (multi-release processes) | RETAIN | 1 | 0 | 1 | ALL (MODERATE, 6.4% of records or value) |
| 8 | DQ-08 | Placeholder date (2001-01-01) | EXCLUDE_FROM_METRIC | 3 | 0 | 1 | M-E01 (LOW, 0.1% of records or value); M-E02 (LOW, 0.8% of records or value); P5-SIG (MODERATE, 1.1% of records or value) |
| 8 | DQ-16 | Zero monetary value | EXCLUDE_FROM_METRIC | 3 | 0 | 1 | M-P01 (LOW, 0.5% of records or value); M-V01 (MODERATE, 1.6% of records or value); P4-BvA (LOW, 0.5% of records or value) |
| 12 | C-06 | Several unrelated budget lines on one OCID (MULTI_PROJECT) | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | P4-BvA (LOW, 0.0% of records or value) |
| 12 | DQ-04 | Elevated tenderer count (101-1,000) | FLAG | 1 | 0 | 0 | M-C01 / M-C02 (LOW, 0.1% of records or value) |
| 12 | DQ-05 | Anomalous tenderer count (>1,000) | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | M-C01 / M-C02 (LOW, 0.4% of records or value) |
| 12 | DQ-09 | Future or impossible date (e.g. year 2922) | EXCLUDE_FROM_METRIC | 3 | 0 | 0 | M-E01 (LOW, 0.0% of records or value); M-E02 (LOW, 0.1% of records or value); P5-SIG (LOW, 0.0% of records or value) |
| 12 | DQ-18 | Release with no parties array | EXCLUDE_FROM_METRIC | 1 | 0 | 0 | M-P01 (LOW, 0.0% of records or value) |
| 12 | DQ-19 | Incomplete buyer ID (bare NG-BPP-) | EXCLUDE_FROM_METRIC | 2 | 0 | 0 | M-P01 (LOW, 0.0% of records or value); ENTITY (LOW, 0.2% of records or value) |


---

*Generated by `python/validation/05_run_analysis_scripts.py`. Raw dataset, stg.* and core.* not modified.*
