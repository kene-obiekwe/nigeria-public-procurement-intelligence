# Findings Claim-Trace Check (Gate D)
# Nigeria Public Procurement Intelligence

> **Generated:** 2026-10-18 09:53 by `python/validation/07_check_findings_trace.py` --live  
> **Checks:** `docs/phase10_findings/findings.md` against `docs/phase10_findings/claim_trace.md`, `docs/phase8_analysis/phase8_analysis_results.md` and the reconciliation pack  
> **Result:** PASS

| Check | Result |
|---|---|
| Claim-trace rows verified against their source cell | 236 of 236 |
| Claim tags | 44 |
| Figures extracted from the findings | 299 |
| Figures without a matching claim-trace row | 0 |
| Claim-trace rows whose figure is not extracted from the findings text (verified, but not auto-located) | 16 |
| Prohibited terms outside the disclaimer section | 0 |
| Tagged figures in the README and portfolio documents (6 files) matched to claim-trace rows | 69 of 69 |
| Reconciliation pack re-run against the database | run 2026-10-18 09:53: 177 figures returned; 8 cited figures compared, 0 mismatches |

## Rows verified but not auto-located in the text

These figures are written without a unit the extractor recognises (for example a small integer). Each was still checked against its source cell.

| Tag | Stated figure | Source |
|---|---|---|
| S5 | 10 | 01/RS5b |
| B4 | 98 | 03/RS9 |
| B4 | 13 | 03/RS9 |
| B6 | 0 | 03/RS7 |
| T4 | 241 | 04/RS4 |
| I3 | 121 | 06/RS3 |
| I4 | 52 | 06/RS4 |
| I4 | 47 | 06/RS4 |
| I4 | 5 | 06/RS4 |
| I4 | 1 | 06/RS4 |
| I4 | 83 | 06/RS5 |
| Q7 | 32 | 07/RS2 |
| X1 | 39 | 03/RS11a |
| X1 | 6 | 03/RS11a |
| B8 | 45 | 03/RS11 |
| E7 | 5 | 05/RS7b |

## Row-by-row result

| Tag | Stated figure | Source | Row | Column | Source value | Scale | Result |
|---|---|---|---|---|---|---|---|
| S1 | 13,537 | 01/RS1 | — | eligible_awards | 13,537 | 1 | ok |
| S1 | 15,763 | 01/RS1 | — | candidate_awards | 15,763 | 1 | ok |
| S1 | 85.9% | 01/RS1 | — | eligible_pct_of_candidate | 85.9 | 1 | ok |
| S1 | 9,800 | 01/RS1 | — | distinct_suppliers | 9,800 | 1 | ok |
| S1 | ₦2,620.2bn | 01/RS1 | — | eligible_value_ngn_bn | 2,620.2 | 1 | ok |
| S1 | 2,226 | 01/RS1 | — | excluded_awards_bare_supplier_id | 2,226 | 1 | ok |
| S1 | ₦670.4bn | 01/RS1 | — | excluded_value_ngn_bn | 670.4 | 1 | ok |
| S1 | ₦670.4bn | REC/SUP-12 | — | SQL value | 670,388,233,365 | 1e-9 | ok |
| S1 | 20.4% | 01/RS1 | — | excluded_pct_of_candidate_value | 20.4 | 1 | ok |
| S2 | 8.0% | 01/RS2 | — | top_1_share_pct | 8.03 | 1 | ok |
| S2 | 21.5% | 01/RS2 | — | top_5_share_pct | 21.46 | 1 | ok |
| S2 | 29.0% | 01/RS2 | — | top_10_share_pct | 29 | 1 | ok |
| S2 | 29.0% | REC/SUP-06 | — | SQL value | 29.00% | 1 | ok |
| S2 | 59.5% | 01/RS2 | — | top_100_share_pct | 59.45 | 1 | ok |
| S2 | 139.4 | 01/RS2 | — | herfindahl_index_0_to_10000 | 139.4 | 1 | ok |
| S2 | 45 suppliers | 01/RS2 | — | suppliers_to_reach_50_pct | 45 | 1 | ok |
| S2 | 872 suppliers | 01/RS2 | — | suppliers_to_reach_80_pct | 872 | 1 | ok |
| S2 | 7,631 | 01/RS2 | — | suppliers_with_one_award | 7,631 | 1 | ok |
| S3 | ₦210.29bn | 01/RS3 | value_rank=1 | value_ngn_bn | 210.29 | 1 | ok |
| S3 | ₦210bn | 01/RS3 | value_rank=1 | value_ngn_bn | 210.29 | 1 | ok |
| S3 | 2 awards | 01/RS3 | value_rank=1 | awards | 2 | 1 | ok |
| S4 | 6.9% | 01/RS4 | procurement_method=National Competitive Bidding | top_1_share_pct | 6.9 | 1 | ok |
| S4 | 7,761 | 01/RS4 | procurement_method=National Competitive Bidding | eligible_awards | 7,761 | 1 | ok |
| S4 | 61.4% | 01/RS4 | procurement_method=Emergency | top_1_share_pct | 61.4 | 1 | ok |
| S4 | 363 awards | 01/RS4 | procurement_method=Emergency | eligible_awards | 363 | 1 | ok |
| S4 | ₦342.3bn | 01/RS4 | procurement_method=Emergency | value_ngn_bn | 342.26 | 1 | ok |
| S4 | 4,238 | 01/RS4 | procurement_method=Emergency | herfindahl_index | 4,238 | 1 | ok |
| S4 | 57.5% | 01/RS4 | procurement_method=(method not stated) | top_1_share_pct | 57.5 | 1 | ok |
| S4 | 105 awards | 01/RS4 | procurement_method=(method not stated) | eligible_awards | 105 | 1 | ok |
| S5 | 166 entities | 01/RS5b | — | entities_in_comparison | 166 | 1 | ok |
| S5 | 10 | 01/RS5b | — | min_awards_threshold | 10 | 1 | ok |
| S5 | 21.0% | 01/RS5b | — | median_top_1_share_pct | 21 | 1 | ok |
| S5 | 13 entities | 01/RS5b | — | entities_where_one_supplier_holds_half | 13 | 1 | ok |
| C1 | 17,253 | 02/RS1 | population=primary (NORMAL, 1-100) | eligible_tenders | 17,253 | 1 | ok |
| C1 | 2 tenderers | 02/RS1 | population=primary (NORMAL, 1-100) | median_tenderers_m_c01 | 2 | 1 | ok |
| C1 | 44.0% | 02/RS1 | population=primary (NORMAL, 1-100) | single_bidder_rate_pct_m_c02 | 44.04 | 1 | ok |
| C1 | 44.0% | REC/COM-05 | — | SQL value | 44.04% | 1 | ok |
| C1 | 17,266 | 02/RS1 | population=sensitivity (NORMAL + ELEVATED) | eligible_tenders | 17,266 | 1 | ok |
| C1 | 44.0% | 02/RS1 | population=sensitivity (NORMAL + ELEVATED) | single_bidder_rate_pct_m_c02 | 44.01 | 1 | ok |
| C1 | 13 tenders | 02/RS2 | participation_band=8  101-1,000 (ELEVATED, sensitivity only) | sensitivity_only_tenders | 13 | 1 | ok |
| C2 | 88.7% | 02/RS2 | participation_band=3  3-5 tenderers | cumulative_pct_of_primary | 88.7 | 1 | ok |
| C2 | 6 tenderers | 02/RS3 | — | p90 | 6 | 1 | ok |
| C3 | 89.5% | 02/RS4 | procurement_method=Direct Procurement | single_bidder_rate_pct | 89.5 | 1 | ok |
| C3 | 1,095 | 02/RS4 | procurement_method=Direct Procurement | eligible_tenders | 1,095 | 1 | ok |
| C3 | 87.2% | 02/RS4 | procurement_method=Sole Source | single_bidder_rate_pct | 87.2 | 1 | ok |
| C3 | 47 tenders | 02/RS4 | procurement_method=Sole Source | eligible_tenders | 47 | 1 | ok |
| C3 | 87.1% | 02/RS4 | procurement_method=Repeat Procurement | single_bidder_rate_pct | 87.1 | 1 | ok |
| C3 | 280 tenders | 02/RS4 | procurement_method=Repeat Procurement | eligible_tenders | 280 | 1 | ok |
| C3 | 39.6% | 02/RS4 | procurement_method=National Competitive Bidding | single_bidder_rate_pct | 39.6 | 1 | ok |
| C3 | 10,129 | 02/RS4 | procurement_method=National Competitive Bidding | eligible_tenders | 10,129 | 1 | ok |
| C3 | 51.6% | 02/RS4 | procurement_method=Emergency | single_bidder_rate_pct | 51.6 | 1 | ok |
| C3 | 395 tenders | 02/RS4 | procurement_method=Emergency | eligible_tenders | 395 | 1 | ok |
| C3 | 23.7% | 02/RS4 | procurement_method=National Shopping | single_bidder_rate_pct | 23.7 | 1 | ok |
| C3 | 594 tenders | 02/RS4 | procurement_method=National Shopping | eligible_tenders | 594 | 1 | ok |
| C4 | 103 entities | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | entities_in_comparison | 103 | 1 | ok |
| C4 | 30 tenders | 05/RS0 | kpi=single_bidder_rate / median_tenderers (competition_n) | min_n | 30 | 1 | ok |
| C4 | 0% | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | single_bidder_rate_pct | 0 | 1 | ok |
| C4 | 212 tenders | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | eligible_tenders | 212 | 1 | ok |
| C4 | 100% | 02/RS6 | buyer_name=NATIONAL BOARD FOR TECHNOLOGY INCUBATION | single_bidder_rate_pct | 100 | 1 | ok |
| C4 | 245 tenders | 02/RS6 | buyer_name=NATIONAL BOARD FOR TECHNOLOGY INCUBATION | eligible_tenders | 245 | 1 | ok |
| C4 | 96.4% | 02/RS6 | buyer_name=FEDERAL MINISTRY OF EDUCATION - HQTRS | single_bidder_rate_pct | 96.4 | 1 | ok |
| C4 | 442 tenders | 02/RS6 | buyer_name=FEDERAL MINISTRY OF EDUCATION - HQTRS | eligible_tenders | 442 | 1 | ok |
| B1 | 15,574 | 03/RS1 | — | eligible_ocids | 15,574 | 1 | ok |
| B1 | 98.8% | 03/RS1 | — | eligible_pct_of_candidate | 98.8 | 1 | ok |
| B1 | ₦12.4tn | 03/RS1 | — | total_budget_ngn_bn | 12,434.5 | 0.001 | ok |
| B1 | ₦3,091.5bn | 03/RS1 | — | total_award_ngn_bn | 3,091.5 | 1 | ok |
| B1 | 0.25 | 03/RS1 | — | aggregate_award_to_budget_ratio | 0.2486 | 1 | ok |
| B1 | 0.93 | 03/RS1 | — | median_ratio | 0.9298 | 1 | ok |
| B1 | 0.93 | REC/BVA-06 | — | SQL value | 0.9298 | 1 | ok |
| B2 | 6,564 | 03/RS3 | ratio_band=3  award within 10% of budget (0.9-1.1) | ocids | 6,564 | 1 | ok |
| B2 | 42.2% | 03/RS3 | ratio_band=3  award within 10% of budget (0.9-1.1) | pct_of_ocids | 42.15 | 1 | ok |
| B2 | 5,300 | 03/RS3 | ratio_band=1  award below half of budget (<0.5) | ocids | 5,300 | 1 | ok |
| B2 | 34.0% | 03/RS3 | ratio_band=1  award below half of budget (<0.5) | pct_of_ocids | 34.03 | 1 | ok |
| B3 | 227 processes | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | ocids | 227 | 1 | ok |
| B3 | 1.5% | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | pct_of_ocids | 1.46 | 1 | ok |
| B3 | ₦1,540.1bn | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | award_ngn_bn | 1,540.11 | 1 | ok |
| B3 | 49.8% | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | pct_of_award_value | 49.82 | 1 | ok |
| B4 | 98 | 03/RS9 | rank_in_band=1 | ocids_above_10x | 98 | 1 | ok |
| B4 | ₦929.8bn | 03/RS9 | rank_in_band=1 | award_ngn_bn | 929.8 | 1 | ok |
| B4 | 60.4% | 03/RS9 | rank_in_band=1 | pct_of_band_value | 60.4 | 1 | ok |
| B4 | 23.3 | 03/RS9 | rank_in_band=1 | median_ratio | 23.3 | 1 | ok |
| B4 | 13 | 03/RS9 | rank_in_band=2 | ocids_above_10x | 13 | 1 | ok |
| B4 | ₦221.8bn | 03/RS9 | rank_in_band=2 | award_ngn_bn | 221.8 | 1 | ok |
| B4 | 9 processes | 03/RS9 | rank_in_band=3 | ocids_above_10x | 9 | 1 | ok |
| B4 | ₦81.9bn | 03/RS9 | rank_in_band=3 | award_ngn_bn | 81.9 | 1 | ok |
| B5 | 56.5% | 03/RS5 | rank_by_abs_variance=1 | cumulative_share_of_abs_variance_pct | 56.5 | 1 | ok |
| B5 | 171 entities | 03/RS5 | rank_by_abs_variance=1 | entities_in_comparison | 171 | 1 | ok |
| B5 | −₦5,559.9bn | 03/RS5 | rank_by_abs_variance=1 | net_variance_ngn_bn | -5,559.89 | 1 | ok |
| B5 | 1,678 | 03/RS5 | rank_by_abs_variance=1 | eligible_ocids | 1,678 | 1 | ok |
| B6 | 9 processes | 03/RS10 | — | ocids_with_ratio_900_to_1100 | 9 | 1 | ok |
| B6 | 0 | 03/RS7 | — | ids_used_by_several_ocids | 0 | 1 | ok |
| B7 | 21.4 | 03/RS5 | rank_by_abs_variance=14 | aggregate_ratio | 21.3731 | 1 | ok |
| B7 | 58 processes | 03/RS5 | rank_by_abs_variance=14 | eligible_ocids | 58 | 1 | ok |
| T1 | 9,040 | 04/RS1 | measure=M-E01 tender open duration (days) | eligible_n | 9,040 | 1 | ok |
| T1 | 28 days | 04/RS1 | measure=M-E01 tender open duration (days) | median_days | 28 | 1 | ok |
| T1 | 7,462 | 04/RS1 | measure=M-E02 award lag, tender start to award (days) | eligible_n | 7,462 | 1 | ok |
| T1 | 97 days | 04/RS1 | measure=M-E02 award lag, tender start to award (days) | median_days | 97 | 1 | ok |
| T1 | 97 days | REC/TIM-05 | — | SQL value | 97 | 1 | ok |
| T1 | 12,006 | 04/RS1 | measure=P5-SIG signature lag, award to signing (days) | eligible_n | 12,006 | 1 | ok |
| T1 | 5 days | 04/RS1 | measure=P5-SIG signature lag, award to signing (days) | median_days | 5 | 1 | ok |
| T2 | 51.9% | 04/RS1b | metric_id=M-E01 | eligible_pct | 51.9 | 1 | ok |
| T2 | 45.2% | 04/RS1b | metric_id=M-E02 | eligible_pct | 45.2 | 1 | ok |
| T2 | 74.0% | 04/RS1b | metric_id=P5-SIG | eligible_pct | 74 | 1 | ok |
| T3 | 64 days | 04/RS2 | measure=M-E01 tender open duration | p90 | 64 | 1 | ok |
| T3 | 267 days | 04/RS2 | measure=M-E02 award lag | p90 | 267 | 1 | ok |
| T3 | 62 days | 04/RS2 | measure=P5-SIG signature lag | p90 | 62 | 1 | ok |
| T3 | 0.7% | 04/RS2 | measure=M-E01 tender open duration | over_1_year_pct | 0.73 | 1 | ok |
| T3 | 3.9% | 04/RS2 | measure=M-E02 award lag | over_1_year_pct | 3.94 | 1 | ok |
| T3 | 1.3% | 04/RS2 | measure=P5-SIG signature lag | over_1_year_pct | 1.3 | 1 | ok |
| T3 | 3,826 | 04/RS2 | measure=P5-SIG signature lag | same_day | 3,826 | 1 | ok |
| T4 | 9 days | 04/RS4 | procurement_method=Emergency | median_award_lag_days | 9 | 1 | ok |
| T4 | 278 processes | 04/RS4 | procurement_method=Emergency | award_lag_n | 278 | 1 | ok |
| T4 | 43 days | 04/RS4 | procurement_method=Selective Tendering | median_award_lag_days | 43 | 1 | ok |
| T4 | 1,339 | 04/RS4 | procurement_method=Selective Tendering | award_lag_n | 1,339 | 1 | ok |
| T4 | 112 days | 04/RS4 | procurement_method=Direct Procurement | median_award_lag_days | 112 | 1 | ok |
| T4 | 241 | 04/RS4 | procurement_method=Direct Procurement | award_lag_n | 241 | 1 | ok |
| T4 | 120 days | 04/RS4 | procurement_method=National Competitive Bidding | median_award_lag_days | 120 | 1 | ok |
| T4 | 4,856 | 04/RS4 | procurement_method=National Competitive Bidding | award_lag_n | 4,856 | 1 | ok |
| T5 | 18 days | 04/RS5 | tender_start_year=2020 | median_days | 18 | 1 | ok |
| T5 | 1,459 | 04/RS5 | tender_start_year=2020 | eligible_n | 1,459 | 1 | ok |
| T5 | 42 days | 04/RS5 | tender_start_year=2021 | median_days | 42 | 1 | ok |
| T5 | 1,578 | 04/RS5 | tender_start_year=2021 | eligible_n | 1,578 | 1 | ok |
| T5 | 41 days | 04/RS6 | award_year=2020 | median_days | 41 | 1 | ok |
| T5 | 1,430 | 04/RS6 | award_year=2020 | eligible_n | 1,430 | 1 | ok |
| T5 | 137 days | 04/RS6 | award_year=2019 | median_days | 137 | 1 | ok |
| T5 | 1,263 | 04/RS6 | award_year=2019 | eligible_n | 1,263 | 1 | ok |
| E1 | 665 | 05/RS1 | — | entities | 665 | 1 | ok |
| E1 | 98,428 | 05/RS1 | — | processes_in_scope | 98,428 | 1 | ok |
| E2 | 40.6% | 05/RS2 | largest_entities=1 | pct_of_award_value | 40.6 | 1 | ok |
| E2 | 5.2% | 05/RS2 | largest_entities=1 | pct_of_processes | 5.2 | 1 | ok |
| E2 | 76.0% | 05/RS2 | largest_entities=10 | pct_of_award_value | 76 | 1 | ok |
| E2 | 26.9% | 05/RS2 | largest_entities=10 | pct_of_processes | 26.9 | 1 | ok |
| E2 | 97.6% | 05/RS2 | largest_entities=100 | pct_of_award_value | 97.6 | 1 | ok |
| E3 | ₦1,335.1bn | 05/RS3 | rank_award_value=1 | award_value_ngn_bn | 1,335.1 | 1 | ok |
| E3 | 1,682 awards | 05/RS3 | rank_award_value=1 | award_n | 1,682 | 1 | ok |
| E3 | ₦175.8bn | 05/RS3 | rank_award_value=3 | award_value_ngn_bn | 175.8 | 1 | ok |
| E3 | 10 awards | 05/RS3 | rank_award_value=3 | award_n | 10 | 1 | ok |
| E3 | 28 processes | 05/RS3 | rank_award_value=3 | process_count | 28 | 1 | ok |
| E4 | 41.7% | 05/RS5 | kpi=single-bidder rate | median | 0.417 | 100 | ok |
| E4 | 103 entities | 05/RS5 | kpi=single-bidder rate | entities_compared | 103 | 1 | ok |
| E4 | 22.2% | 05/RS5 | kpi=top-supplier value share | median | 0.222 | 100 | ok |
| E4 | 173 entities | 05/RS5 | kpi=top-supplier value share | entities_compared | 173 | 1 | ok |
| E4 | 99.1% | 05/RS5 | kpi=implementation coverage rate | median | 0.991 | 100 | ok |
| E4 | 123 entities | 05/RS5 | kpi=implementation coverage rate | entities_compared | 123 | 1 | ok |
| E4 | 6.4% | 05/RS5 | kpi=tender reach rate | median | 0.064 | 100 | ok |
| E4 | 373 entities | 05/RS5 | kpi=tender reach rate | entities_compared | 373 | 1 | ok |
| E5 | 65 entities | 05/RS6 | value_quartile=1 | entities | 65 | 1 | ok |
| E5 | 94.8% | 05/RS6 | value_quartile=1 | pct_of_award_value | 94.8 | 1 | ok |
| E6 | 3.7% | 05/RS4 | rank_award_value=1 | single_bidder_pct | 3.7 | 1 | ok |
| E6 | 1,635 | 05/RS4 | rank_award_value=1 | competition_n | 1,635 | 1 | ok |
| E6 | 11.1% | 05/RS4 | rank_award_value=1 | top_supplier_share_pct | 11.1 | 1 | ok |
| E6 | 21.6% | 05/RS4 | rank_award_value=1 | implementation_coverage_pct | 21.6 | 1 | ok |
| E6 | 1,677 contracts | 05/RS4 | rank_award_value=1 | contract_n | 1,677 | 1 | ok |
| I1 | 14,140 | 06/RS1 | — | contracts_with_implementation_data | 14,140 | 1 | ok |
| I1 | 16,221 | 06/RS1 | — | eligible_contracts | 16,221 | 1 | ok |
| I1 | 87.2% | 06/RS1 | — | coverage_rate_pct_m_i01 | 87.17 | 1 | ok |
| I1 | 87.2% | REC/IMP-03 | — | SQL value | 87.17% | 1 | ok |
| I1 | 2,081 | 06/RS1 | — | contracts_without_implementation_data | 2,081 | 1 | ok |
| I2 | 78.9% | 06/RS2 | implementation_data_type=1  transactions and milestones | pct_of_contracts | 78.89 | 1 | ok |
| I2 | 8.3% | 06/RS2 | implementation_data_type=2  milestones only | pct_of_contracts | 8.29 | 1 | ok |
| I2 | 12.8% | 06/RS2 | implementation_data_type=4  no implementation data | pct_of_contracts | 12.83 | 1 | ok |
| I3 | 86.9% | 06/RS3 | contract_status=active | coverage_rate_pct | 86.94 | 1 | ok |
| I3 | 15,653 | 06/RS3 | contract_status=active | contracts | 15,653 | 1 | ok |
| I3 | 74.4% | 06/RS3 | contract_status=pending | coverage_rate_pct | 74.38 | 1 | ok |
| I3 | 121 | 06/RS3 | contract_status=pending | contracts | 121 | 1 | ok |
| I4 | 123 entities | 06/RS5 | rank_lowest_coverage=1 | entities_in_comparison | 123 | 1 | ok |
| I4 | 20 contracts | 06/RS4 | entity_coverage_band=1  full coverage (100%) | min_contracts_threshold | 20 | 1 | ok |
| I4 | 52 | 06/RS4 | entity_coverage_band=1  full coverage (100%) | entities | 52 | 1 | ok |
| I4 | 47 | 06/RS4 | entity_coverage_band=2  90% to under 100% | entities | 47 | 1 | ok |
| I4 | 5 | 06/RS4 | entity_coverage_band=4  under 50% | entities | 5 | 1 | ok |
| I4 | 1 | 06/RS4 | entity_coverage_band=5  none reported (0%) | entities | 1 | 1 | ok |
| I4 | 21.6% | 06/RS5 | rank_lowest_coverage=3 | coverage_rate_pct | 21.6 | 1 | ok |
| I4 | 1,677 contracts | 06/RS5 | rank_lowest_coverage=3 | contracts | 1,677 | 1 | ok |
| I4 | 21.6% | REC/IMP-05 | — | SQL value | 21.59% | 1 | ok |
| I4 | 4.8% | 06/RS5 | rank_lowest_coverage=2 | coverage_rate_pct | 4.8 | 1 | ok |
| I4 | 83 | 06/RS5 | rank_lowest_coverage=2 | contracts | 83 | 1 | ok |
| I5 | 17.7% | 06/RS6 | stage=tender | pct_of_all_ocids | 17.68 | 1 | ok |
| I5 | 17,405 processes | 06/RS6 | stage=tender | ocids_reaching_stage_or_beyond | 17,405 | 1 | ok |
| I5 | 95.0% | 06/RS6 | stage=award | conversion_from_previous_stage_pct | 94.96 | 1 | ok |
| I5 | 98.2% | 06/RS6 | stage=contract | conversion_from_previous_stage_pct | 98.15 | 1 | ok |
| I5 | 87.2% | 06/RS6 | stage=implementation | conversion_from_previous_stage_pct | 87.23 | 1 | ok |
| Q1 | 82.3% | 07/RS2 | metric_id=M-E03; dq_ref=DQ-02 | pct_of_candidate | 82.32 | 1 | ok |
| Q1 | 82.3% | REC/EXE-13 | — | SQL value | 82.32% | 1 | ok |
| Q1 | 98,454 | 07/RS2 | metric_id=M-E03; dq_ref=DQ-02 | candidate_records | 98,454 | 1 | ok |
| Q2 | 8,339 | 07/RS1 | metric_id=M-E01 | lost_to_non_dq_rule_only | 8,339 | 1 | ok |
| Q2 | 8,365 | 07/RS1 | metric_id=M-E01 | excluded_records | 8,365 | 1 | ok |
| Q3 | 135 awards | 07/RS2 | metric_id=M-E02; dq_ref=DATE-ORDER | records_with_issue | 135 | 1 | ok |
| Q3 | 734 contracts | 07/RS2 | metric_id=P5-SIG; dq_ref=DATE-ORDER | records_with_issue | 734 | 1 | ok |
| Q4 | 34.1% | 07/RS2 | metric_id=M-S01; dq_ref=DQ-13 | value_pct_of_candidate | 34.1 | 1 | ok |
| Q5 | 78.9% | 07/RS2 | metric_id=M-I01; dq_ref=DQ-11 | pct_of_candidate | 78.89 | 1 | ok |
| Q6 | 99.4% | 07/RS1 | metric_id=M-P01 | eligible_pct | 99.4 | 1 | ok |
| Q6 | 97,353 | 07/RS1 | metric_id=M-P01 | candidate_records | 97,353 | 1 | ok |
| Q6 | 99.1% | 07/RS1 | metric_id=M-C01 / M-C02 | eligible_pct | 99.1 | 1 | ok |
| Q6 | 95.4% | 07/RS1 | metric_id=M-V01 | eligible_pct | 95.4 | 1 | ok |
| Q6 | 98.8% | 07/RS1 | metric_id=P4-BvA | eligible_pct | 98.8 | 1 | ok |
| Q6 | 85.9% | 07/RS1 | metric_id=M-S01 | eligible_pct | 85.9 | 1 | ok |
| Q6 | 51.9% | 07/RS1 | metric_id=M-E01 | eligible_pct | 51.9 | 1 | ok |
| Q6 | 45.2% | 07/RS1 | metric_id=M-E02 | eligible_pct | 45.2 | 1 | ok |
| Q6 | 74.0% | 07/RS1 | metric_id=P5-SIG | eligible_pct | 74 | 1 | ok |
| Q7 | 32 | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | records_with_issue | 32 | 1 | ok |
| Q7 | 50.8% | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | value_pct_of_candidate | 50.8 | 1 | ok |
| Q7 | ₦96.4tn | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | affected_value_ngn_bn | 96,441.9 | 0.001 | ok |
| Q7 | 23.3% | 07/RS2 | metric_id=M-V01; dq_ref=DQ-07 | value_pct_of_candidate | 23.3 | 1 | ok |
| Q7 | ₦1,004.2bn | 07/RS2 | metric_id=M-V01; dq_ref=DQ-07 | affected_value_ngn_bn | 1,004.2 | 1 | ok |
| Q8 | 188 awards | 07/RS2 | metric_id=M-V01; dq_ref=DQ-20 | records_with_issue | 188 | 1 | ok |
| Q8 | 1.7% | 07/RS2 | metric_id=M-V01; dq_ref=DQ-20 | value_pct_of_candidate | 1.7 | 1 | ok |
| X1 | 45 awards | 03/RS11a | — | flagged_awards | 45 | 1 | ok |
| X1 | 39 | 03/RS11a | — | dropped_decimal | 39 | 1 | ok |
| X1 | 6 | 03/RS11a | — | sibling_lot | 6 | 1 | ok |
| X1 | ₦509.5bn | 03/RS11a | — | flagged_value_ngn_bn | 509.5 | 1 | ok |
| X1 | 15.5% | 03/RS11a | — | pct_of_m_v01_award_value | 15.5 | 1 | ok |
| X1 | 31 entities | 03/RS11a | — | entities | 31 | 1 | ok |
| S6 | 39 | 01/RS6 | scenario=2  without DQ-21 flagged awards | flagged_awards_in_m_s01 | 39 | 1 | ok |
| S6 | 5.2% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_1_share_pct | 5.22 | 1 | ok |
| S6 | ₦112.09bn | 01/RS6 | scenario=2  without DQ-21 flagged awards | largest_supplier_value_ngn_bn | 112.09 | 1 | ok |
| S6 | 26.1% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_10_share_pct | 26.13 | 1 | ok |
| S6 | 53.2% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_100_share_pct | 53.22 | 1 | ok |
| S6 | 101.3 | 01/RS6 | scenario=2  without DQ-21 flagged awards | herfindahl_index_0_to_10000 | 101.3 | 1 | ok |
| S6 | 55.3% | 01/RS6b | procurement_method=Emergency | top_1_share_pct_without_flagged | 55.3 | 1 | ok |
| S6 | 3,197 | 01/RS6b | procurement_method=Emergency | herfindahl_without_flagged | 3,197 | 1 | ok |
| B8 | 45 | 03/RS11 | scenario=2  without DQ-21 flagged awards | flagged_ocids_in_comparison | 45 | 1 | ok |
| B8 | 186 processes | 03/RS11 | scenario=2  without DQ-21 flagged awards | ocids_above_10x | 186 | 1 | ok |
| B8 | ₦1,030.9bn | 03/RS11 | scenario=2  without DQ-21 flagged awards | above_10x_award_ngn_bn | 1,030.9 | 1 | ok |
| B8 | 39.9% | 03/RS11 | scenario=2  without DQ-21 flagged awards | above_10x_pct_of_award_value | 39.93 | 1 | ok |
| B8 | 0.21 | 03/RS11 | scenario=2  without DQ-21 flagged awards | aggregate_award_to_budget_ratio | 0.208 | 1 | ok |
| B8 | 0.93 | 03/RS11 | scenario=2  without DQ-21 flagged awards | median_ratio | 0.9285 | 1 | ok |
| B8 | 87.7% | 03/RS11b | rank_in_band=1 | pct_of_band_value | 87.7 | 1 | ok |
| B8 | 93 processes | 03/RS11b | rank_in_band=1 | ocids_above_10x | 93 | 1 | ok |
| B8 | ₦904.1bn | 03/RS11b | rank_in_band=1 | award_ngn_bn | 904.1 | 1 | ok |
| E7 | 47.1% | 05/RS7 | largest_entities=1 | pct_of_award_value_without_flagged | 47.1 | 1 | ok |
| E7 | 76.2% | 05/RS7 | largest_entities=10 | pct_of_award_value_without_flagged | 76.2 | 1 | ok |
| E7 | ₦470.1bn | 05/RS7b | rank_without=2 | award_value_published_ngn_bn | 470.1 | 1 | ok |
| E7 | ₦257.8bn | 05/RS7b | rank_without=2 | award_value_without_flagged_ngn_bn | 257.8 | 1 | ok |
| E7 | ₦86.2bn | 05/RS7b | rank_without=8 | award_value_published_ngn_bn | 86.2 | 1 | ok |
| E7 | ₦32.4bn | 05/RS7b | rank_without=8 | award_value_without_flagged_ngn_bn | 32.4 | 1 | ok |
| E7 | 5 | 05/RS7b | rank_without=8 | flagged_awards | 5 | 1 | ok |

---

*Generated by `python/validation/07_check_findings_trace.py`. Read-only: no source or database object changed.*
