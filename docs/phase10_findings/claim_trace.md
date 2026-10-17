# Claim Trace (Gate D evidence)
# Nigeria Public Procurement Intelligence

> **Phase:** 10 — Business Interpretation, Findings & Recommendations
> **Date:** 2026-10-17
> **Purpose:** every figure in [`findings.md`](findings.md) maps to one row below: the claim tag it carries in the
> findings, the figure as written, and the SQL output it comes from.
> **Check:** `python/validation/07_check_findings_trace.py` (results in
> [`claim_trace_check_results.md`](claim_trace_check_results.md)).

## How to read a row

| Column | Meaning |
|---|---|
| Tag | The claim tag in `findings.md`. One tag can carry several figures. |
| Stated figure | The figure exactly as written in the findings. |
| Source | `NN/RSx` is result set `RSx` of `sql/06_analysis/NN_*.sql`, as logged in `docs/phase8_analysis/phase8_analysis_results.md`. `REC/ID` is figure `ID` of the reconciliation pack `dashboard/reconciliation_expected_values.sql`, as logged in `dashboard/reconciliation_log.md`. |
| Row | The row of the result set (`column=value`; `—` for a one-row result set). |
| Column | The column holding the value. |
| Source value | The value exactly as the source shows it. |
| Scale | Multiplier from the source value to the stated figure (for example `0.001` for NGN billions to trillions, `100` for a fraction to a percentage). The stated figure must equal source value × scale, rounded to the stated precision. |
| Eligible n | The population the figure rests on. |

`REC/` rows repeat a figure that also comes from a Phase 8 result set; they show that the dashboard's validated SQL
gives the same value.

## Supplier concentration (§3)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| S1 | Awards with a usable supplier ID | 13,537 | 01/RS1 | — | eligible_awards | 13,537 | 1 | 13,537 awards |
| S1 | M-S01 candidate (M-V01 eligible) awards | 15,763 | 01/RS1 | — | candidate_awards | 15,763 | 1 | 15,763 awards |
| S1 | Share of candidates with a usable supplier ID | 85.9% | 01/RS1 | — | eligible_pct_of_candidate | 85.9 | 1 | 15,763 awards |
| S1 | Distinct suppliers | 9,800 | 01/RS1 | — | distinct_suppliers | 9,800 | 1 | 13,537 awards |
| S1 | Value attributed to suppliers | ₦2,620.2bn | 01/RS1 | — | eligible_value_ngn_bn | 2,620.2 | 1 | 13,537 awards |
| S1 | Awards excluded: bare supplier ID (DQ-14) | 2,226 | 01/RS1 | — | excluded_awards_bare_supplier_id | 2,226 | 1 | 15,763 awards |
| S1 | Value excluded | ₦670.4bn | 01/RS1 | — | excluded_value_ngn_bn | 670.4 | 1 | 15,763 awards |
| S1 | Value excluded (reconciliation pack) | ₦670.4bn | REC/SUP-12 | — | SQL value | 670,388,233,365 | 1e-9 | 15,763 awards |
| S1 | Excluded share of eligible award value | 20.4% | 01/RS1 | — | excluded_pct_of_candidate_value | 20.4 | 1 | 15,763 awards |
| S2 | Top-1 supplier share | 8.0% | 01/RS2 | — | top_1_share_pct | 8.03 | 1 | 13,537 awards |
| S2 | Top-5 supplier share | 21.5% | 01/RS2 | — | top_5_share_pct | 21.46 | 1 | 13,537 awards |
| S2 | Top-10 supplier share | 29.0% | 01/RS2 | — | top_10_share_pct | 29 | 1 | 13,537 awards |
| S2 | Top-10 supplier share (reconciliation pack) | 29.0% | REC/SUP-06 | — | SQL value | 29.00% | 1 | 13,537 awards |
| S2 | Top-100 supplier share | 59.5% | 01/RS2 | — | top_100_share_pct | 59.45 | 1 | 13,537 awards |
| S2 | Herfindahl index (0 to 10,000 scale) | 139.4 | 01/RS2 | — | herfindahl_index_0_to_10000 | 139.4 | 1 | 13,537 awards |
| S2 | Suppliers holding half of value | 45 suppliers | 01/RS2 | — | suppliers_to_reach_50_pct | 45 | 1 | 9,800 suppliers |
| S2 | Suppliers holding four-fifths of value | 872 suppliers | 01/RS2 | — | suppliers_to_reach_80_pct | 872 | 1 | 9,800 suppliers |
| S2 | Suppliers with a single award | 7,631 | 01/RS2 | — | suppliers_with_one_award | 7,631 | 1 | 9,800 suppliers |
| S3 | Largest supplier's value | ₦210.29bn | 01/RS3 | value_rank=1 | value_ngn_bn | 210.29 | 1 | 13,537 awards |
| S3 | Largest supplier's value (rounded) | ₦210bn | 01/RS3 | value_rank=1 | value_ngn_bn | 210.29 | 1 | 13,537 awards |
| S3 | Largest supplier's awards | 2 awards | 01/RS3 | value_rank=1 | awards | 2 | 1 | 13,537 awards |
| S4 | Top-1 share, National Competitive Bidding | 6.9% | 01/RS4 | procurement_method=National Competitive Bidding | top_1_share_pct | 6.9 | 1 | 7,761 awards |
| S4 | Awards, National Competitive Bidding | 7,761 | 01/RS4 | procurement_method=National Competitive Bidding | eligible_awards | 7,761 | 1 | 7,761 awards |
| S4 | Top-1 share, Emergency | 61.4% | 01/RS4 | procurement_method=Emergency | top_1_share_pct | 61.4 | 1 | 363 awards |
| S4 | Awards, Emergency | 363 awards | 01/RS4 | procurement_method=Emergency | eligible_awards | 363 | 1 | 363 awards |
| S4 | Value, Emergency | ₦342.3bn | 01/RS4 | procurement_method=Emergency | value_ngn_bn | 342.26 | 1 | 363 awards |
| S4 | Herfindahl index, Emergency | 4,238 | 01/RS4 | procurement_method=Emergency | herfindahl_index | 4,238 | 1 | 363 awards |
| S4 | Top-1 share, method not stated | 57.5% | 01/RS4 | procurement_method=(method not stated) | top_1_share_pct | 57.5 | 1 | 105 awards |
| S4 | Awards, method not stated | 105 awards | 01/RS4 | procurement_method=(method not stated) | eligible_awards | 105 | 1 | 105 awards |
| S5 | Entities in the comparison | 166 entities | 01/RS5b | — | entities_in_comparison | 166 | 1 | 166 entities |
| S5 | Minimum eligible awards per entity | 10 | 01/RS5b | — | min_awards_threshold | 10 | 1 | 166 entities |
| S5 | Median entity top-1 supplier share | 21.0% | 01/RS5b | — | median_top_1_share_pct | 21 | 1 | 166 entities |
| S5 | Entities where one supplier holds half or more | 13 entities | 01/RS5b | — | entities_where_one_supplier_holds_half | 13 | 1 | 166 entities |

## Competition (§4)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| C1 | Primary tenders (1 to 100 tenderers) | 17,253 | 02/RS1 | population=primary (NORMAL, 1-100) | eligible_tenders | 17,253 | 1 | 17,253 tenders |
| C1 | Median tenderers (M-C01) | 2 tenderers | 02/RS1 | population=primary (NORMAL, 1-100) | median_tenderers_m_c01 | 2 | 1 | 17,253 tenders |
| C1 | Single-bidder rate (M-C02) | 44.0% | 02/RS1 | population=primary (NORMAL, 1-100) | single_bidder_rate_pct_m_c02 | 44.04 | 1 | 17,253 tenders |
| C1 | Single-bidder rate (reconciliation pack) | 44.0% | REC/COM-05 | — | SQL value | 44.04% | 1 | 17,253 tenders |
| C1 | Sensitivity population | 17,266 | 02/RS1 | population=sensitivity (NORMAL + ELEVATED) | eligible_tenders | 17,266 | 1 | 17,266 tenders |
| C1 | Single-bidder rate, sensitivity | 44.0% | 02/RS1 | population=sensitivity (NORMAL + ELEVATED) | single_bidder_rate_pct_m_c02 | 44.01 | 1 | 17,266 tenders |
| C1 | Elevated tenders added in the sensitivity population | 13 tenders | 02/RS2 | participation_band=8  101-1,000 (ELEVATED, sensitivity only) | sensitivity_only_tenders | 13 | 1 | 17,266 tenders |
| C2 | Share with five or fewer tenderers | 88.7% | 02/RS2 | participation_band=3  3-5 tenderers | cumulative_pct_of_primary | 88.7 | 1 | 17,253 tenders |
| C2 | 90th percentile of tenderers | 6 tenderers | 02/RS3 | — | p90 | 6 | 1 | 17,253 tenders |
| C3 | Single-bidder rate, Direct Procurement | 89.5% | 02/RS4 | procurement_method=Direct Procurement | single_bidder_rate_pct | 89.5 | 1 | 1,095 tenders |
| C3 | Tenders, Direct Procurement | 1,095 | 02/RS4 | procurement_method=Direct Procurement | eligible_tenders | 1,095 | 1 | 1,095 tenders |
| C3 | Single-bidder rate, Sole Source | 87.2% | 02/RS4 | procurement_method=Sole Source | single_bidder_rate_pct | 87.2 | 1 | 47 tenders |
| C3 | Tenders, Sole Source | 47 tenders | 02/RS4 | procurement_method=Sole Source | eligible_tenders | 47 | 1 | 47 tenders |
| C3 | Single-bidder rate, Repeat Procurement | 87.1% | 02/RS4 | procurement_method=Repeat Procurement | single_bidder_rate_pct | 87.1 | 1 | 280 tenders |
| C3 | Tenders, Repeat Procurement | 280 tenders | 02/RS4 | procurement_method=Repeat Procurement | eligible_tenders | 280 | 1 | 280 tenders |
| C3 | Single-bidder rate, National Competitive Bidding | 39.6% | 02/RS4 | procurement_method=National Competitive Bidding | single_bidder_rate_pct | 39.6 | 1 | 10,129 tenders |
| C3 | Tenders, National Competitive Bidding | 10,129 | 02/RS4 | procurement_method=National Competitive Bidding | eligible_tenders | 10,129 | 1 | 10,129 tenders |
| C3 | Single-bidder rate, Emergency | 51.6% | 02/RS4 | procurement_method=Emergency | single_bidder_rate_pct | 51.6 | 1 | 395 tenders |
| C3 | Tenders, Emergency | 395 tenders | 02/RS4 | procurement_method=Emergency | eligible_tenders | 395 | 1 | 395 tenders |
| C3 | Single-bidder rate, National Shopping | 23.7% | 02/RS4 | procurement_method=National Shopping | single_bidder_rate_pct | 23.7 | 1 | 594 tenders |
| C3 | Tenders, National Shopping | 594 tenders | 02/RS4 | procurement_method=National Shopping | eligible_tenders | 594 | 1 | 594 tenders |
| C4 | Entities with at least 30 primary tenders | 103 entities | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | entities_in_comparison | 103 | 1 | 103 entities |
| C4 | Minimum tenders per entity | 30 tenders | 05/RS0 | kpi=single_bidder_rate / median_tenderers (competition_n) | min_n | 30 | 1 | 103 entities |
| C4 | Lowest entity single-bidder rate | 0% | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | single_bidder_rate_pct | 0 | 1 | 212 tenders |
| C4 | Tenders, University of Abuja | 212 tenders | 02/RS6 | buyer_name=UNIVERSITY OF ABUJA | eligible_tenders | 212 | 1 | 212 tenders |
| C4 | Highest entity single-bidder rate | 100% | 02/RS6 | buyer_name=NATIONAL BOARD FOR TECHNOLOGY INCUBATION | single_bidder_rate_pct | 100 | 1 | 245 tenders |
| C4 | Tenders, National Board for Technology Incubation | 245 tenders | 02/RS6 | buyer_name=NATIONAL BOARD FOR TECHNOLOGY INCUBATION | eligible_tenders | 245 | 1 | 245 tenders |
| C4 | Single-bidder rate, Federal Ministry of Education HQ | 96.4% | 02/RS6 | buyer_name=FEDERAL MINISTRY OF EDUCATION - HQTRS | single_bidder_rate_pct | 96.4 | 1 | 442 tenders |
| C4 | Tenders, Federal Ministry of Education HQ | 442 tenders | 02/RS6 | buyer_name=FEDERAL MINISTRY OF EDUCATION - HQTRS | eligible_tenders | 442 | 1 | 442 tenders |

## Budget versus award (§5)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| B1 | Comparable processes | 15,574 | 03/RS1 | — | eligible_ocids | 15,574 | 1 | 15,574 OCIDs |
| B1 | Share of eligible awards comparable | 98.8% | 03/RS1 | — | eligible_pct_of_candidate | 98.8 | 1 | 15,763 awards |
| B1 | Total budget of comparable processes | ₦12.4tn | 03/RS1 | — | total_budget_ngn_bn | 12,434.5 | 0.001 | 15,574 OCIDs |
| B1 | Total award value of comparable processes | ₦3,091.5bn | 03/RS1 | — | total_award_ngn_bn | 3,091.5 | 1 | 15,574 OCIDs |
| B1 | Aggregate award-to-budget ratio | 0.25 | 03/RS1 | — | aggregate_award_to_budget_ratio | 0.2486 | 1 | 15,574 OCIDs |
| B1 | Median award-to-budget ratio | 0.93 | 03/RS1 | — | median_ratio | 0.9298 | 1 | 15,574 OCIDs |
| B1 | Median ratio (reconciliation pack) | 0.93 | REC/BVA-06 | — | SQL value | 0.9298 | 1 | 15,574 OCIDs |
| B2 | Processes within a tenth of budget | 6,564 | 03/RS3 | ratio_band=3  award within 10% of budget (0.9-1.1) | ocids | 6,564 | 1 | 15,574 OCIDs |
| B2 | Share within a tenth of budget | 42.2% | 03/RS3 | ratio_band=3  award within 10% of budget (0.9-1.1) | pct_of_ocids | 42.15 | 1 | 15,574 OCIDs |
| B2 | Processes awarded below half of budget | 5,300 | 03/RS3 | ratio_band=1  award below half of budget (<0.5) | ocids | 5,300 | 1 | 15,574 OCIDs |
| B2 | Share below half of budget | 34.0% | 03/RS3 | ratio_band=1  award below half of budget (<0.5) | pct_of_ocids | 34.03 | 1 | 15,574 OCIDs |
| B3 | Processes above ten times budget | 227 processes | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | ocids | 227 | 1 | 15,574 OCIDs |
| B3 | Share of processes above ten times budget | 1.5% | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | pct_of_ocids | 1.46 | 1 | 15,574 OCIDs |
| B3 | Award value above ten times budget | ₦1,540.1bn | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | award_ngn_bn | 1,540.11 | 1 | 15,574 OCIDs |
| B3 | Share of compared award value | 49.8% | 03/RS3 | ratio_band=6  award above 10x budget (check units / budget entry) | pct_of_award_value | 49.82 | 1 | 15,574 OCIDs |
| B4 | Works & Housing HQ processes above ten times budget | 98 | 03/RS9 | rank_in_band=1 | ocids_above_10x | 98 | 1 | 227 OCIDs |
| B4 | Works & Housing HQ value in the group | ₦929.8bn | 03/RS9 | rank_in_band=1 | award_ngn_bn | 929.8 | 1 | 227 OCIDs |
| B4 | Works & Housing HQ share of the group's value | 60.4% | 03/RS9 | rank_in_band=1 | pct_of_band_value | 60.4 | 1 | 227 OCIDs |
| B4 | Works & Housing HQ median ratio in the group | 23.3 | 03/RS9 | rank_in_band=1 | median_ratio | 23.3 | 1 | 98 OCIDs |
| B4 | FCTA processes above ten times budget | 13 | 03/RS9 | rank_in_band=2 | ocids_above_10x | 13 | 1 | 227 OCIDs |
| B4 | FCTA value in the group | ₦221.8bn | 03/RS9 | rank_in_band=2 | award_ngn_bn | 221.8 | 1 | 227 OCIDs |
| B4 | HADEJIA-JAMAÄ»ARE RBDA processes above ten times budget | 9 processes | 03/RS9 | rank_in_band=3 | ocids_above_10x | 9 | 1 | 227 OCIDs |
| B4 | HADEJIA-JAMAÄ»ARE RBDA value in the group | ₦81.9bn | 03/RS9 | rank_in_band=3 | award_ngn_bn | 81.9 | 1 | 227 OCIDs |
| B5 | Works & Housing HQ share of summed absolute difference | 56.5% | 03/RS5 | rank_by_abs_variance=1 | cumulative_share_of_abs_variance_pct | 56.5 | 1 | 171 entities |
| B5 | Entities with at least 10 comparable processes | 171 entities | 03/RS5 | rank_by_abs_variance=1 | entities_in_comparison | 171 | 1 | 171 entities |
| B5 | Works & Housing HQ net difference | −₦5,559.9bn | 03/RS5 | rank_by_abs_variance=1 | net_variance_ngn_bn | -5,559.89 | 1 | 1,678 OCIDs |
| B5 | Works & Housing HQ comparable processes | 1,678 | 03/RS5 | rank_by_abs_variance=1 | eligible_ocids | 1,678 | 1 | 1,678 OCIDs |
| B6 | Processes near a thousand times budget | 9 processes | 03/RS10 | — | ocids_with_ratio_900_to_1100 | 9 | 1 | 15,574 OCIDs |
| B6 | Budget lines used by more than one process | 0 | 03/RS7 | — | ids_used_by_several_ocids | 0 | 1 | 15,574 budget lines |
| B7 | HADEJIA-JAMAÄ»ARE RBDA aggregate award-to-budget ratio | 21.4 | 03/RS5 | rank_by_abs_variance=14 | aggregate_ratio | 21.3731 | 1 | 58 OCIDs |
| B7 | HADEJIA-JAMAÄ»ARE RBDA comparable processes | 58 processes | 03/RS5 | rank_by_abs_variance=14 | eligible_ocids | 58 | 1 | 58 OCIDs |

## Procurement-cycle timing (§6)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| T1 | Tender duration: eligible processes | 9,040 | 04/RS1 | measure=M-E01 tender open duration (days) | eligible_n | 9,040 | 1 | 9,040 OCIDs |
| T1 | Tender duration: median | 28 days | 04/RS1 | measure=M-E01 tender open duration (days) | median_days | 28 | 1 | 9,040 OCIDs |
| T1 | Award lag: eligible processes | 7,462 | 04/RS1 | measure=M-E02 award lag, tender start to award (days) | eligible_n | 7,462 | 1 | 7,462 OCIDs |
| T1 | Award lag: median | 97 days | 04/RS1 | measure=M-E02 award lag, tender start to award (days) | median_days | 97 | 1 | 7,462 OCIDs |
| T1 | Award lag: median (reconciliation pack) | 97 days | REC/TIM-05 | — | SQL value | 97 | 1 | 7,462 OCIDs |
| T1 | Signature lag: eligible contracts | 12,006 | 04/RS1 | measure=P5-SIG signature lag, award to signing (days) | eligible_n | 12,006 | 1 | 12,006 contracts |
| T1 | Signature lag: median | 5 days | 04/RS1 | measure=P5-SIG signature lag, award to signing (days) | median_days | 5 | 1 | 12,006 contracts |
| T2 | Tender duration coverage | 51.9% | 04/RS1b | metric_id=M-E01 | eligible_pct | 51.9 | 1 | 17,405 OCIDs |
| T2 | Award lag coverage | 45.2% | 04/RS1b | metric_id=M-E02 | eligible_pct | 45.2 | 1 | 16,527 OCIDs |
| T2 | Signature lag coverage | 74.0% | 04/RS1b | metric_id=P5-SIG | eligible_pct | 74 | 1 | 16,221 contracts |
| T3 | Tender duration: 90th percentile | 64 days | 04/RS2 | measure=M-E01 tender open duration | p90 | 64 | 1 | 9,040 OCIDs |
| T3 | Award lag: 90th percentile | 267 days | 04/RS2 | measure=M-E02 award lag | p90 | 267 | 1 | 7,462 OCIDs |
| T3 | Signature lag: 90th percentile | 62 days | 04/RS2 | measure=P5-SIG signature lag | p90 | 62 | 1 | 12,006 contracts |
| T3 | Tender duration over one year | 0.7% | 04/RS2 | measure=M-E01 tender open duration | over_1_year_pct | 0.73 | 1 | 9,040 OCIDs |
| T3 | Award lag over one year | 3.9% | 04/RS2 | measure=M-E02 award lag | over_1_year_pct | 3.94 | 1 | 7,462 OCIDs |
| T3 | Signature lag over one year | 1.3% | 04/RS2 | measure=P5-SIG signature lag | over_1_year_pct | 1.3 | 1 | 12,006 contracts |
| T3 | Same-day signature lags | 3,826 | 04/RS2 | measure=P5-SIG signature lag | same_day | 3,826 | 1 | 12,006 contracts |
| T4 | Median award lag, Emergency | 9 days | 04/RS4 | procurement_method=Emergency | median_award_lag_days | 9 | 1 | 278 OCIDs |
| T4 | Award-lag processes, Emergency | 278 processes | 04/RS4 | procurement_method=Emergency | award_lag_n | 278 | 1 | 278 OCIDs |
| T4 | Median award lag, Selective Tendering | 43 days | 04/RS4 | procurement_method=Selective Tendering | median_award_lag_days | 43 | 1 | 1,339 OCIDs |
| T4 | Award-lag processes, Selective Tendering | 1,339 | 04/RS4 | procurement_method=Selective Tendering | award_lag_n | 1,339 | 1 | 1,339 OCIDs |
| T4 | Median award lag, Direct Procurement | 112 days | 04/RS4 | procurement_method=Direct Procurement | median_award_lag_days | 112 | 1 | 241 OCIDs |
| T4 | Award-lag processes, Direct Procurement | 241 | 04/RS4 | procurement_method=Direct Procurement | award_lag_n | 241 | 1 | 241 OCIDs |
| T4 | Median award lag, National Competitive Bidding | 120 days | 04/RS4 | procurement_method=National Competitive Bidding | median_award_lag_days | 120 | 1 | 4,856 OCIDs |
| T4 | Award-lag processes, National Competitive Bidding | 4,856 | 04/RS4 | procurement_method=National Competitive Bidding | award_lag_n | 4,856 | 1 | 4,856 OCIDs |
| T5 | Median tender duration, tenders starting in 2020 | 18 days | 04/RS5 | tender_start_year=2020 | median_days | 18 | 1 | 1,459 OCIDs |
| T5 | Tenders starting in 2020 | 1,459 | 04/RS5 | tender_start_year=2020 | eligible_n | 1,459 | 1 | 1,459 OCIDs |
| T5 | Median tender duration, tenders starting in 2021 | 42 days | 04/RS5 | tender_start_year=2021 | median_days | 42 | 1 | 1,578 OCIDs |
| T5 | Tenders starting in 2021 | 1,578 | 04/RS5 | tender_start_year=2021 | eligible_n | 1,578 | 1 | 1,578 OCIDs |
| T5 | Median award lag, awards in 2020 | 41 days | 04/RS6 | award_year=2020 | median_days | 41 | 1 | 1,430 OCIDs |
| T5 | Awards in 2020 | 1,430 | 04/RS6 | award_year=2020 | eligible_n | 1,430 | 1 | 1,430 OCIDs |
| T5 | Median award lag, awards in 2019 | 137 days | 04/RS6 | award_year=2019 | median_days | 137 | 1 | 1,263 OCIDs |
| T5 | Awards in 2019 | 1,263 | 04/RS6 | award_year=2019 | eligible_n | 1,263 | 1 | 1,263 OCIDs |

## Procuring-entity benchmarking (§7)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| E1 | Procuring entities | 665 | 05/RS1 | — | entities | 665 | 1 | 665 entities |
| E1 | Processes across entities | 98,428 | 05/RS1 | — | processes_in_scope | 98,428 | 1 | 665 entities |
| E2 | Largest entity: share of award value | 40.6% | 05/RS2 | largest_entities=1 | pct_of_award_value | 40.6 | 1 | 665 entities |
| E2 | Largest entity: share of processes | 5.2% | 05/RS2 | largest_entities=1 | pct_of_processes | 5.2 | 1 | 665 entities |
| E2 | Ten largest: share of award value | 76.0% | 05/RS2 | largest_entities=10 | pct_of_award_value | 76 | 1 | 665 entities |
| E2 | Ten largest: share of processes | 26.9% | 05/RS2 | largest_entities=10 | pct_of_processes | 26.9 | 1 | 665 entities |
| E2 | Hundred largest: share of award value | 97.6% | 05/RS2 | largest_entities=100 | pct_of_award_value | 97.6 | 1 | 665 entities |
| E3 | Works & Housing HQ award value | ₦1,335.1bn | 05/RS3 | rank_award_value=1 | award_value_ngn_bn | 1,335.1 | 1 | 1,682 awards |
| E3 | Works & Housing HQ awards | 1,682 awards | 05/RS3 | rank_award_value=1 | award_n | 1,682 | 1 | 1,682 awards |
| E3 | FMC Taraba award value | ₦175.8bn | 05/RS3 | rank_award_value=3 | award_value_ngn_bn | 175.8 | 1 | 10 awards |
| E3 | FMC Taraba awards | 10 awards | 05/RS3 | rank_award_value=3 | award_n | 10 | 1 | 10 awards |
| E3 | FMC Taraba processes | 28 processes | 05/RS3 | rank_award_value=3 | process_count | 28 | 1 | 28 OCIDs |
| E4 | Median entity single-bidder rate | 41.7% | 05/RS5 | kpi=single-bidder rate | median | 0.417 | 100 | 103 entities |
| E4 | Entities compared, single-bidder rate | 103 entities | 05/RS5 | kpi=single-bidder rate | entities_compared | 103 | 1 | 103 entities |
| E4 | Median entity top-supplier share | 22.2% | 05/RS5 | kpi=top-supplier value share | median | 0.222 | 100 | 173 entities |
| E4 | Entities compared, top-supplier share | 173 entities | 05/RS5 | kpi=top-supplier value share | entities_compared | 173 | 1 | 173 entities |
| E4 | Median entity implementation coverage | 99.1% | 05/RS5 | kpi=implementation coverage rate | median | 0.991 | 100 | 123 entities |
| E4 | Entities compared, implementation coverage | 123 entities | 05/RS5 | kpi=implementation coverage rate | entities_compared | 123 | 1 | 123 entities |
| E4 | Median entity tender reach | 6.4% | 05/RS5 | kpi=tender reach rate | median | 0.064 | 100 | 373 entities |
| E4 | Entities compared, tender reach | 373 entities | 05/RS5 | kpi=tender reach rate | entities_compared | 373 | 1 | 373 entities |
| E5 | Entities in the top value quartile | 65 entities | 05/RS6 | value_quartile=1 | entities | 65 | 1 | 259 entities with awards |
| E5 | Top value quartile: share of award value | 94.8% | 05/RS6 | value_quartile=1 | pct_of_award_value | 94.8 | 1 | 259 entities with awards |
| E6 | Works & Housing HQ single-bidder rate | 3.7% | 05/RS4 | rank_award_value=1 | single_bidder_pct | 3.7 | 1 | 1,635 tenders |
| E6 | Works & Housing HQ competition population | 1,635 | 05/RS4 | rank_award_value=1 | competition_n | 1,635 | 1 | 1,635 tenders |
| E6 | Works & Housing HQ top-supplier share | 11.1% | 05/RS4 | rank_award_value=1 | top_supplier_share_pct | 11.1 | 1 | 1,682 awards |
| E6 | Works & Housing HQ implementation coverage | 21.6% | 05/RS4 | rank_award_value=1 | implementation_coverage_pct | 21.6 | 1 | 1,677 contracts |
| E6 | Works & Housing HQ contracts | 1,677 contracts | 05/RS4 | rank_award_value=1 | contract_n | 1,677 | 1 | 1,677 contracts |

## Implementation reporting coverage (§8)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| I1 | Contracts with implementation data | 14,140 | 06/RS1 | — | contracts_with_implementation_data | 14,140 | 1 | 16,221 contracts |
| I1 | Contracts in scope | 16,221 | 06/RS1 | — | eligible_contracts | 16,221 | 1 | 16,221 contracts |
| I1 | Coverage rate (M-I01) | 87.2% | 06/RS1 | — | coverage_rate_pct_m_i01 | 87.17 | 1 | 16,221 contracts |
| I1 | Coverage rate (reconciliation pack) | 87.2% | REC/IMP-03 | — | SQL value | 87.17% | 1 | 16,221 contracts |
| I1 | Contracts without implementation data | 2,081 | 06/RS1 | — | contracts_without_implementation_data | 2,081 | 1 | 16,221 contracts |
| I2 | Transactions and milestones | 78.9% | 06/RS2 | implementation_data_type=1  transactions and milestones | pct_of_contracts | 78.89 | 1 | 16,221 contracts |
| I2 | Milestones only | 8.3% | 06/RS2 | implementation_data_type=2  milestones only | pct_of_contracts | 8.29 | 1 | 16,221 contracts |
| I2 | No implementation data | 12.8% | 06/RS2 | implementation_data_type=4  no implementation data | pct_of_contracts | 12.83 | 1 | 16,221 contracts |
| I3 | Coverage, active contracts | 86.9% | 06/RS3 | contract_status=active | coverage_rate_pct | 86.94 | 1 | 15,653 contracts |
| I3 | Active contracts | 15,653 | 06/RS3 | contract_status=active | contracts | 15,653 | 1 | 15,653 contracts |
| I3 | Coverage, pending contracts | 74.4% | 06/RS3 | contract_status=pending | coverage_rate_pct | 74.38 | 1 | 121 contracts |
| I3 | Pending contracts | 121 | 06/RS3 | contract_status=pending | contracts | 121 | 1 | 121 contracts |
| I4 | Entities with at least 20 contracts | 123 entities | 06/RS5 | rank_lowest_coverage=1 | entities_in_comparison | 123 | 1 | 123 entities |
| I4 | Minimum contracts per entity | 20 contracts | 06/RS4 | entity_coverage_band=1  full coverage (100%) | min_contracts_threshold | 20 | 1 | 123 entities |
| I4 | Entities with full coverage | 52 | 06/RS4 | entity_coverage_band=1  full coverage (100%) | entities | 52 | 1 | 123 entities |
| I4 | Entities at 90% to under 100% | 47 | 06/RS4 | entity_coverage_band=2  90% to under 100% | entities | 47 | 1 | 123 entities |
| I4 | Entities under half | 5 | 06/RS4 | entity_coverage_band=4  under 50% | entities | 5 | 1 | 123 entities |
| I4 | Entities with none | 1 | 06/RS4 | entity_coverage_band=5  none reported (0%) | entities | 1 | 1 | 123 entities |
| I4 | Works & Housing HQ coverage | 21.6% | 06/RS5 | rank_lowest_coverage=3 | coverage_rate_pct | 21.6 | 1 | 1,677 contracts |
| I4 | Works & Housing HQ contracts | 1,677 contracts | 06/RS5 | rank_lowest_coverage=3 | contracts | 1,677 | 1 | 1,677 contracts |
| I4 | Works & Housing HQ coverage (reconciliation pack) | 21.6% | REC/IMP-05 | — | SQL value | 21.59% | 1 | 1,677 contracts |
| I4 | National Inland Waterways Authority coverage | 4.8% | 06/RS5 | rank_lowest_coverage=2 | coverage_rate_pct | 4.8 | 1 | 83 contracts |
| I4 | National Inland Waterways Authority contracts | 83 | 06/RS5 | rank_lowest_coverage=2 | contracts | 83 | 1 | 83 contracts |
| I5 | Share of processes reaching tender | 17.7% | 06/RS6 | stage=tender | pct_of_all_ocids | 17.68 | 1 | 98,454 OCIDs |
| I5 | Processes reaching tender | 17,405 processes | 06/RS6 | stage=tender | ocids_reaching_stage_or_beyond | 17,405 | 1 | 98,454 OCIDs |
| I5 | Tender to award conversion | 95.0% | 06/RS6 | stage=award | conversion_from_previous_stage_pct | 94.96 | 1 | 17,405 OCIDs |
| I5 | Award to contract conversion | 98.2% | 06/RS6 | stage=contract | conversion_from_previous_stage_pct | 98.15 | 1 | 16,527 OCIDs |
| I5 | Contract to implementation conversion | 87.2% | 06/RS6 | stage=implementation | conversion_from_previous_stage_pct | 87.23 | 1 | 16,221 OCIDs |

## Data-quality impact (§9) and limitations (§12)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| Q1 | Planning-only processes (DQ-02) | 82.3% | 07/RS2 | metric_id=M-E03; dq_ref=DQ-02 | pct_of_candidate | 82.32 | 1 | 98,454 OCIDs |
| Q1 | Planning-only share (reconciliation pack) | 82.3% | REC/EXE-13 | — | SQL value | 82.32% | 1 | 98,454 OCIDs |
| Q1 | All processes in scope | 98,454 | 07/RS2 | metric_id=M-E03; dq_ref=DQ-02 | candidate_records | 98,454 | 1 | 98,454 OCIDs |
| Q2 | M-E01 records lost to missing dates only | 8,339 | 07/RS1 | metric_id=M-E01 | lost_to_non_dq_rule_only | 8,339 | 1 | 17,405 OCIDs |
| Q2 | M-E01 records excluded | 8,365 | 07/RS1 | metric_id=M-E01 | excluded_records | 8,365 | 1 | 17,405 OCIDs |
| Q3 | Awards dated before tender start (M-E02) | 135 awards | 07/RS2 | metric_id=M-E02; dq_ref=DATE-ORDER | records_with_issue | 135 | 1 | 16,527 OCIDs |
| Q3 | Contracts signed before award (signature lag) | 734 contracts | 07/RS2 | metric_id=P5-SIG; dq_ref=DATE-ORDER | records_with_issue | 734 | 1 | 16,221 contracts |
| Q4 | Eligible supplier value with several name variants (DQ-13) | 34.1% | 07/RS2 | metric_id=M-S01; dq_ref=DQ-13 | value_pct_of_candidate | 34.1 | 1 | 13,537 awards |
| Q5 | Contracts with transactions lacking dates (DQ-11) | 78.9% | 07/RS2 | metric_id=M-I01; dq_ref=DQ-11 | pct_of_candidate | 78.89 | 1 | 16,221 contracts |
| Q6 | Eligible share, M-P01 budget | 99.4% | 07/RS1 | metric_id=M-P01 | eligible_pct | 99.4 | 1 | 97,353 budget lines |
| Q6 | M-P01 candidate budget lines | 97,353 | 07/RS1 | metric_id=M-P01 | candidate_records | 97,353 | 1 | 97,353 budget lines |
| Q6 | Eligible share, M-C01 / M-C02 competition | 99.1% | 07/RS1 | metric_id=M-C01 / M-C02 | eligible_pct | 99.1 | 1 | 17,405 OCIDs |
| Q6 | Eligible share, M-V01 award value | 95.4% | 07/RS1 | metric_id=M-V01 | eligible_pct | 95.4 | 1 | 16,527 OCIDs |
| Q6 | Eligible share, budget-to-award | 98.8% | 07/RS1 | metric_id=P4-BvA | eligible_pct | 98.8 | 1 | 15,763 awards |
| Q6 | Eligible share, M-S01 supplier concentration | 85.9% | 07/RS1 | metric_id=M-S01 | eligible_pct | 85.9 | 1 | 15,763 awards |
| Q6 | Eligible share, M-E01 tender duration | 51.9% | 07/RS1 | metric_id=M-E01 | eligible_pct | 51.9 | 1 | 17,405 OCIDs |
| Q6 | Eligible share, M-E02 award lag | 45.2% | 07/RS1 | metric_id=M-E02 | eligible_pct | 45.2 | 1 | 16,527 OCIDs |
| Q6 | Eligible share, signature lag | 74.0% | 07/RS1 | metric_id=P5-SIG | eligible_pct | 74 | 1 | 16,221 contracts |
| Q7 | Extreme budget lines (DQ-06) | 32 | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | records_with_issue | 32 | 1 | 97,353 budget lines |
| Q7 | Extreme budgets: share of candidate budget value | 50.8% | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | value_pct_of_candidate | 50.8 | 1 | 97,353 budget lines |
| Q7 | Extreme budgets: value | ₦96.4tn | 07/RS2 | metric_id=M-P01; dq_ref=DQ-06 | affected_value_ngn_bn | 96,441.9 | 0.001 | 97,353 budget lines |
| Q7 | Extreme award (DQ-07): share of candidate award value | 23.3% | 07/RS2 | metric_id=M-V01; dq_ref=DQ-07 | value_pct_of_candidate | 23.3 | 1 | 16,527 OCIDs |
| Q7 | Extreme award: value | ₦1,004.2bn | 07/RS2 | metric_id=M-V01; dq_ref=DQ-07 | affected_value_ngn_bn | 1,004.2 | 1 | 16,527 OCIDs |
| Q8 | Test-entity awards removed before M-V01 (DQ-20) | 188 awards | 07/RS2 | metric_id=M-V01; dq_ref=DQ-20 | records_with_issue | 188 | 1 | 16,527 OCIDs |
| Q8 | Test-entity share of candidate award value | 1.7% | 07/RS2 | metric_id=M-V01; dq_ref=DQ-20 | value_pct_of_candidate | 1.7 | 1 | 16,527 OCIDs |

## Phase 10.1 sensitivity: DQ-21 possible award scale errors (§1, §3, §5, §7, §9, §10, §11, §12)

| Tag | Claim | Stated figure | Source | Row | Column | Source value | Scale | Eligible n |
|---|---|---|---|---|---|---|---|---|
| X1 | Awards flagged POSSIBLE_SCALE_ERROR | 45 awards | 03/RS11a | — | flagged_awards | 45 | 1 | 15,763 awards (M-V01) |
| X1 | Flagged by the dropped-decimal test | 39 | 03/RS11a | — | dropped_decimal | 39 | 1 | 15,763 awards (M-V01) |
| X1 | Flagged by the sibling-lot test | 6 | 03/RS11a | — | sibling_lot | 6 | 1 | 15,763 awards (M-V01) |
| X1 | Flagged award value | ₦509.5bn | 03/RS11a | — | flagged_value_ngn_bn | 509.5 | 1 | 15,763 awards (M-V01) |
| X1 | Flagged share of M-V01 award value | 15.5% | 03/RS11a | — | pct_of_m_v01_award_value | 15.5 | 1 | 15,763 awards (M-V01) |
| X1 | Entities with a flagged award | 31 entities | 03/RS11a | — | entities | 31 | 1 | 15,763 awards (M-V01) |
| S6 | Flagged awards inside the M-S01 population | 39 | 01/RS6 | scenario=2  without DQ-21 flagged awards | flagged_awards_in_m_s01 | 39 | 1 | 13,537 awards |
| S6 | Top-1 supplier share without flagged awards | 5.2% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_1_share_pct | 5.22 | 1 | 13,498 awards |
| S6 | Largest supplier's value without flagged awards | ₦112.09bn | 01/RS6 | scenario=2  without DQ-21 flagged awards | largest_supplier_value_ngn_bn | 112.09 | 1 | 13,498 awards |
| S6 | Top-10 supplier share without flagged awards | 26.1% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_10_share_pct | 26.13 | 1 | 13,498 awards |
| S6 | Top-100 supplier share without flagged awards | 53.2% | 01/RS6 | scenario=2  without DQ-21 flagged awards | top_100_share_pct | 53.22 | 1 | 13,498 awards |
| S6 | Herfindahl index without flagged awards | 101.3 | 01/RS6 | scenario=2  without DQ-21 flagged awards | herfindahl_index_0_to_10000 | 101.3 | 1 | 13,498 awards |
| S6 | Emergency top-1 supplier share without flagged awards | 55.3% | 01/RS6b | procurement_method=Emergency | top_1_share_pct_without_flagged | 55.3 | 1 | 363 awards less 2 flagged |
| S6 | Emergency Herfindahl index without flagged awards | 3,197 | 01/RS6b | procurement_method=Emergency | herfindahl_without_flagged | 3,197 | 1 | 363 awards less 2 flagged |
| B8 | Comparable processes carrying a flagged award | 45 | 03/RS11 | scenario=2  without DQ-21 flagged awards | flagged_ocids_in_comparison | 45 | 1 | 15,574 OCIDs |
| B8 | Processes above ten times budget without flagged awards | 186 processes | 03/RS11 | scenario=2  without DQ-21 flagged awards | ocids_above_10x | 186 | 1 | 15,529 OCIDs |
| B8 | Above-ten-times value without flagged awards | ₦1,030.9bn | 03/RS11 | scenario=2  without DQ-21 flagged awards | above_10x_award_ngn_bn | 1,030.9 | 1 | 15,529 OCIDs |
| B8 | Above-ten-times share of compared award value without flagged awards | 39.9% | 03/RS11 | scenario=2  without DQ-21 flagged awards | above_10x_pct_of_award_value | 39.93 | 1 | 15,529 OCIDs |
| B8 | Aggregate ratio without flagged awards | 0.21 | 03/RS11 | scenario=2  without DQ-21 flagged awards | aggregate_award_to_budget_ratio | 0.208 | 1 | 15,529 OCIDs |
| B8 | Median ratio without flagged awards | 0.93 | 03/RS11 | scenario=2  without DQ-21 flagged awards | median_ratio | 0.9285 | 1 | 15,529 OCIDs |
| B8 | Works & Housing HQ share of the group without flagged awards | 87.7% | 03/RS11b | rank_in_band=1 | pct_of_band_value | 87.7 | 1 | 186 OCIDs |
| B8 | Works & Housing HQ processes in the group without flagged awards | 93 processes | 03/RS11b | rank_in_band=1 | ocids_above_10x | 93 | 1 | 186 OCIDs |
| B8 | Works & Housing HQ value in the group without flagged awards | ₦904.1bn | 03/RS11b | rank_in_band=1 | award_ngn_bn | 904.1 | 1 | 186 OCIDs |
| E7 | Largest entity's share without flagged awards | 47.1% | 05/RS7 | largest_entities=1 | pct_of_award_value_without_flagged | 47.1 | 1 | 665 entities |
| E7 | Ten largest entities' share without flagged awards | 76.2% | 05/RS7 | largest_entities=10 | pct_of_award_value_without_flagged | 76.2 | 1 | 665 entities |
| E7 | FCTA award value as published | ₦470.1bn | 05/RS7b | rank_without=2 | award_value_published_ngn_bn | 470.1 | 1 | 844 awards |
| E7 | FCTA award value without flagged awards | ₦257.8bn | 05/RS7b | rank_without=2 | award_value_without_flagged_ngn_bn | 257.8 | 1 | 844 awards less 3 flagged |
| E7 | HADEJIA-JAMAÄ»ARE RBDA award value as published | ₦86.2bn | 05/RS7b | rank_without=8 | award_value_published_ngn_bn | 86.2 | 1 | 58 awards |
| E7 | HADEJIA-JAMAÄ»ARE RBDA award value without flagged awards | ₦32.4bn | 05/RS7b | rank_without=8 | award_value_without_flagged_ngn_bn | 32.4 | 1 | 58 awards less 5 flagged |
| E7 | HADEJIA-JAMAÄ»ARE RBDA flagged awards | 5 | 05/RS7b | rank_without=8 | flagged_awards | 5 | 1 | 58 awards |

---

*Claim trace version 1.1 — 2026-10-17 (Phase 10.1 DQ-21 sensitivity rows added). Every row is checked by `python/validation/07_check_findings_trace.py`.*
