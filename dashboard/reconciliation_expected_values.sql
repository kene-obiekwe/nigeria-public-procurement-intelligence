-- ============================================================
-- NOCOPO — Phase 9: expected values for dashboard-to-SQL reconciliation
-- ============================================================
-- Phase 9 exit gate: "every figure shown on the dashboard reconciles with its
-- source SQL view/query". This one read-only query returns every headline figure
-- the dashboard shows, computed in SQL from analytics.* views only, each with its
-- eligible n. Compare each row with the matching card / visual value
-- (dashboard/README.md §6 names the DAX measure for every figure_id) and record
-- the result in dashboard/reconciliation_log.md.
--
-- Run (read-only; works for the nocopo_bi role):
--     psql -h localhost -p 5433 -U postgres -d nocopo_db -f dashboard/reconciliation_expected_values.sql
-- or paste it into pgAdmin. It takes about 10 s (it reads the register and
-- vw_dq_impact once each).
--
-- Columns
--   figure_id    key used in the dashboard README and the log
--   page         dashboard page
--   figure       what is shown
--   dax_measure  the Power BI measure (or visual) that must equal expected_value
--   slice        the filter state in which the value holds ('none' = all slicers cleared)
--   expected_value  numeric; shares and rates are fractions (0.4404 = 44.04%)
--   unit         count | NGN | days | ratio | share | index
--   eligible_n   the population the figure is computed on
--
-- Tolerance: counts, days and bands must match exactly. NGN amounts must match
-- to the whole naira (set the monetary columns to Fixed decimal number in Power
-- BI). Ratios and shares must match to the displayed precision (4 decimals).
-- ============================================================
WITH
-- ---------- base populations (analytics.* only) ----------
comp  AS MATERIALIZED (SELECT * FROM analytics.vw_competition_eligible),
aw    AS MATERIALIZED (SELECT * FROM analytics.vw_award_value_eligible),
sup   AS MATERIALIZED (SELECT * FROM analytics.vw_supplier_award_eligible),
bva   AS MATERIALIZED (SELECT * FROM analytics.vw_budget_award_comparison),
td    AS MATERIALIZED (SELECT * FROM analytics.vw_tender_duration_eligible),
al    AS MATERIALIZED (SELECT * FROM analytics.vw_award_lag_eligible),
sl    AS MATERIALIZED (SELECT * FROM analytics.vw_signature_lag_eligible),
lc    AS MATERIALIZED (SELECT * FROM analytics.vw_lifecycle_stage),
ct    AS MATERIALIZED (SELECT * FROM analytics.vw_contract_implementation_coverage),
eb    AS MATERIALIZED (SELECT * FROM analytics.vw_entity_benchmark),
reg   AS MATERIALIZED (SELECT * FROM analytics.vw_metric_population),
dq    AS MATERIALIZED (SELECT * FROM analytics.vw_dq_impact),
-- ---------- M-S01 supplier ranking ----------
sup_tot AS MATERIALIZED (
    SELECT supplier_id, count(*) AS awards, sum(award_value_amount) AS v FROM sup GROUP BY supplier_id),
sup_rk AS MATERIALIZED (
    SELECT supplier_id, awards, v,
           row_number() OVER (ORDER BY v DESC, supplier_id) AS rn,
           sum(v) OVER () AS tot
    FROM sup_tot),
-- same ranking inside one procurement method
sup_m AS MATERIALIZED (
    SELECT coalesce(procurement_method_details, '(method not stated)') AS m, supplier_id,
           sum(award_value_amount) AS v
    FROM sup GROUP BY 1, 2),
sup_m_rk AS MATERIALIZED (
    SELECT m, supplier_id, v,
           row_number() OVER (PARTITION BY m ORDER BY v DESC, supplier_id) AS rn,
           sum(v) OVER (PARTITION BY m) AS tot
    FROM sup_m),
-- ---------- entity ranking (665 entities; shares of the entity-level total) ----------
eb_rk AS MATERIALIZED (
    SELECT buyer_id, coalesce(award_value_total, 0) AS v,
           row_number() OVER (ORDER BY coalesce(award_value_total, 0) DESC, buyer_id) AS rn,
           sum(coalesce(award_value_total, 0)) OVER () AS tot
    FROM eb),
-- ---------- band helpers (presentation bins; same cut-offs as sql/06_analysis) ----------
bva_b AS (
    SELECT CASE WHEN award_to_budget_ratio < 0.5 THEN 1 WHEN award_to_budget_ratio < 0.9 THEN 2
                WHEN award_to_budget_ratio <= 1.1 THEN 3 WHEN award_to_budget_ratio <= 1.5 THEN 4
                WHEN award_to_budget_ratio <= 10 THEN 5 ELSE 6 END AS b
    FROM bva),
comp_b AS (
    SELECT CASE WHEN number_of_tenderers = 1 THEN 1 WHEN number_of_tenderers = 2 THEN 2
                WHEN number_of_tenderers <= 5 THEN 3 WHEN number_of_tenderers <= 10 THEN 4
                WHEN number_of_tenderers <= 20 THEN 5 WHEN number_of_tenderers <= 50 THEN 6
                WHEN number_of_tenderers <= 100 THEN 7 ELSE 8 END AS b,
           in_primary_population AS prim
    FROM comp),
dur AS (
    SELECT 1 AS mk, tender_duration_days AS d FROM td
    UNION ALL SELECT 2, award_lag_days FROM al
    UNION ALL SELECT 3, signature_lag_days FROM sl),
dur_b AS (
    SELECT mk, CASE WHEN d <= 7 THEN 1 WHEN d <= 30 THEN 2 WHEN d <= 90 THEN 3 WHEN d <= 180 THEN 4
                    WHEN d <= 365 THEN 5 ELSE 6 END AS b
    FROM dur),
impl_t AS (
    SELECT CASE WHEN transaction_count > 0 AND implementation_milestone_count > 0 THEN 1
                WHEN implementation_milestone_count > 0 THEN 2
                WHEN transaction_count > 0 THEN 3 ELSE 4 END AS t
    FROM ct),
stage AS (
    SELECT k, count(*) FILTER (WHERE highest_stage_rank >= k) AS reached
    FROM lc CROSS JOIN generate_series(1, 5) AS k
    GROUP BY k),
-- ---------- the figures ----------
f (figure_id, page, figure, dax_measure, slice, expected_value, unit, eligible_n) AS (

 -- ======== EXE: executive overview (all slicers cleared) ========
 SELECT 'EXE-01', 'Executive overview', 'Procurement processes in scope', '[Processes (n)]', 'none',
        count(*)::numeric, 'count', count(*) FROM lc
 UNION ALL SELECT 'EXE-02', 'Executive overview', 'Planned budget, NGN', '[Planned Budget (NGN)]', 'none',
        sum(budget_amount), 'NGN', count(*) FROM analytics.vw_budget_eligible
 UNION ALL SELECT 'EXE-03', 'Executive overview', 'Awarded value, NGN (M-V01)', '[Award Value (NGN)]', 'none',
        sum(award_value_amount), 'NGN', count(*) FROM aw
 UNION ALL SELECT 'EXE-04', 'Executive overview', 'Median award value, NGN (M-V01)', '[Median Award Value (NGN)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_value_amount)::numeric, 'NGN', count(*) FROM aw
 UNION ALL SELECT 'EXE-05', 'Executive overview', 'Single-bidder rate, primary (M-C02)', '[Single-Bidder Rate (primary)]', 'none',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM comp WHERE in_primary_population
 UNION ALL SELECT 'EXE-06', 'Executive overview', 'Median tenderers, primary (M-C01)', '[Median Tenderers (primary)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)::numeric, 'count', count(*) FROM comp WHERE in_primary_population
 UNION ALL SELECT 'EXE-07', 'Executive overview', 'Top-10 supplier share of value (M-S01)', '[Top N Supplier Share] with N = 10', 'none',
        sum(v) FILTER (WHERE rn <= 10) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'EXE-08', 'Executive overview', 'M-S01 excluded value, share of eligible award value', '[M-S01 Excluded Value Share]', 'none',
        1 - (SELECT sum(award_value_amount) FROM sup) / (SELECT sum(award_value_amount) FROM aw), 'share', (SELECT count(*) FROM aw)
 UNION ALL SELECT 'EXE-09', 'Executive overview', 'Median award-to-budget ratio', '[Median Award-to-Budget Ratio]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio)::numeric, 'ratio', count(*) FROM bva
 UNION ALL SELECT 'EXE-10', 'Executive overview', 'Median tender open duration, days (M-E01)', '[Median Tender Duration (days)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days)::numeric, 'days', count(*) FROM td
 UNION ALL SELECT 'EXE-11', 'Executive overview', 'Median award lag, days (M-E02)', '[Median Award Lag (days)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)::numeric, 'days', count(*) FROM al
 UNION ALL SELECT 'EXE-12', 'Executive overview', 'Implementation reporting coverage (M-I01)', '[Implementation Coverage Rate]', 'none',
        avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM ct
 UNION ALL SELECT 'EXE-13', 'Executive overview', 'Processes that stop at planning stage (DQ-02 disclosure)', '[Planning-Only Share]', 'none',
        avg(CASE WHEN highest_stage_rank = 1 THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM lc

 -- ======== SUP: supplier concentration (M-S01) ========
 UNION ALL SELECT 'SUP-01', 'Supplier concentration', 'Eligible awards with a usable supplier ID', '[M-S01 Eligible Awards]', 'none',
        count(DISTINCT award_id)::numeric, 'count', count(DISTINCT award_id) FROM sup
 UNION ALL SELECT 'SUP-02', 'Supplier concentration', 'Distinct suppliers', '[Suppliers (n)]', 'none',
        count(DISTINCT supplier_id)::numeric, 'count', count(DISTINCT award_id) FROM sup
 UNION ALL SELECT 'SUP-03', 'Supplier concentration', 'Value attributed to suppliers, NGN', '[Supplier Value (NGN)]', 'none',
        sum(award_value_amount), 'NGN', count(DISTINCT award_id) FROM sup
 UNION ALL SELECT 'SUP-04', 'Supplier concentration', 'Top-1 supplier share', '[Top N Supplier Share] with N = 1', 'none',
        sum(v) FILTER (WHERE rn <= 1) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-05', 'Supplier concentration', 'Top-5 supplier share', '[Top N Supplier Share] with N = 5', 'none',
        sum(v) FILTER (WHERE rn <= 5) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-06', 'Supplier concentration', 'Top-10 supplier share', '[Top N Supplier Share] with N = 10', 'none',
        sum(v) FILTER (WHERE rn <= 10) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-07', 'Supplier concentration', 'Top-20 supplier share', '[Top N Supplier Share] with N = 20', 'none',
        sum(v) FILTER (WHERE rn <= 20) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-08', 'Supplier concentration', 'Top-100 supplier share', '[Top N Supplier Share] with N = 100', 'none',
        sum(v) FILTER (WHERE rn <= 100) / max(tot), 'share', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-09', 'Supplier concentration', 'Herfindahl index (0 to 10,000)', '[Supplier HHI]', 'none',
        sum((v / tot) * (v / tot)) * 10000, 'index', (SELECT count(DISTINCT award_id) FROM sup) FROM sup_rk
 UNION ALL SELECT 'SUP-10', 'Supplier concentration', 'Suppliers with exactly one award', '[Suppliers With One Award]', 'none',
        count(*) FILTER (WHERE awards = 1)::numeric, 'count', count(*) FROM sup_tot
 UNION ALL SELECT 'SUP-11', 'Supplier concentration', 'Disclosure: eligible awards excluded (no usable supplier ID)', '[M-S01 Excluded Awards]', 'none',
        ((SELECT count(*) FROM aw) - (SELECT count(DISTINCT award_id) FROM sup))::numeric, 'count', (SELECT count(*) FROM aw)
 UNION ALL SELECT 'SUP-12', 'Supplier concentration', 'Disclosure: excluded award value, NGN', '[M-S01 Excluded Value (NGN)]', 'none',
        (SELECT sum(award_value_amount) FROM aw) - (SELECT sum(award_value_amount) FROM sup), 'NGN', (SELECT count(*) FROM aw)
 UNION ALL SELECT 'SUP-13', 'Supplier concentration', 'Disclosure: excluded share of eligible award value', '[M-S01 Excluded Value Share]', 'none',
        1 - (SELECT sum(award_value_amount) FROM sup) / (SELECT sum(award_value_amount) FROM aw), 'share', (SELECT count(*) FROM aw)
 UNION ALL SELECT 'SUP-14', 'Supplier concentration', 'Disclosure read from the DQ view: excluded awards (DQ-14)', '[M-S01 Excluded Awards (DQ view)]', 'none',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-S01' AND dq_ref = 'DQ-14'
 UNION ALL SELECT 'SUP-15', 'Supplier concentration', 'Disclosure read from the DQ view: excluded value (DQ-14), NGN', '[M-S01 Excluded Value (DQ view)]', 'none',
        affected_value_ngn, 'NGN', candidate_records FROM dq WHERE metric_id = 'M-S01' AND dq_ref = 'DQ-14'
 UNION ALL SELECT 'SUP-16', 'Supplier concentration', 'Top-1 supplier share within National Competitive Bidding', '[Top N Supplier Share] with N = 1', 'method = National Competitive Bidding',
        sum(v) FILTER (WHERE rn <= 1) / max(tot), 'share',
        (SELECT count(DISTINCT award_id) FROM sup WHERE procurement_method_details = 'National Competitive Bidding') FROM sup_m_rk WHERE m = 'National Competitive Bidding'
 UNION ALL SELECT 'SUP-17', 'Supplier concentration', 'Top-1 supplier share within Emergency', '[Top N Supplier Share] with N = 1', 'method = Emergency',
        sum(v) FILTER (WHERE rn <= 1) / max(tot), 'share',
        (SELECT count(DISTINCT award_id) FROM sup WHERE procurement_method_details = 'Emergency') FROM sup_m_rk WHERE m = 'Emergency'
 UNION ALL SELECT 'SUP-18', 'Supplier concentration', 'Herfindahl index within Emergency', '[Supplier HHI]', 'method = Emergency',
        sum((v / tot) * (v / tot)) * 10000, 'index',
        (SELECT count(DISTINCT award_id) FROM sup WHERE procurement_method_details = 'Emergency') FROM sup_m_rk WHERE m = 'Emergency'

 -- ======== COM: competition (M-C01, M-C02) ========
 UNION ALL SELECT 'COM-01', 'Competition', 'Eligible tenders, primary (1-100 tenderers)', '[Competition n (primary)]', 'none',
        count(*)::numeric, 'count', count(*) FROM comp WHERE in_primary_population
 UNION ALL SELECT 'COM-02', 'Competition', 'Eligible tenders, sensitivity (adds 101-1,000)', '[Competition n (sensitivity)]', 'none',
        count(*)::numeric, 'count', count(*) FROM comp
 UNION ALL SELECT 'COM-03', 'Competition', 'Median tenderers, primary (M-C01)', '[Median Tenderers (primary)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)::numeric, 'count', count(*) FROM comp WHERE in_primary_population
 UNION ALL SELECT 'COM-04', 'Competition', 'Median tenderers, sensitivity', '[Median Tenderers (sensitivity)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)::numeric, 'count', count(*) FROM comp
 UNION ALL SELECT 'COM-05', 'Competition', 'Single-bidder rate, primary (M-C02)', '[Single-Bidder Rate (primary)]', 'none',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM comp WHERE in_primary_population
 UNION ALL SELECT 'COM-06', 'Competition', 'Single-bidder rate, sensitivity', '[Single-Bidder Rate (sensitivity)]', 'none',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM comp
 UNION ALL SELECT 'COM-07', 'Competition', 'Single-bidder rate, primary, Direct Procurement', '[Single-Bidder Rate (primary)]', 'method = Direct Procurement',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*)
        FROM comp WHERE in_primary_population AND procurement_method_details = 'Direct Procurement'
 UNION ALL SELECT 'COM-08', 'Competition', 'Single-bidder rate, primary, National Competitive Bidding', '[Single-Bidder Rate (primary)]', 'method = National Competitive Bidding',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*)
        FROM comp WHERE in_primary_population AND procurement_method_details = 'National Competitive Bidding'
 UNION ALL SELECT 'COM-09', 'Competition', 'Single-bidder rate, primary, tender status active', '[Single-Bidder Rate (primary)]', 'tender_status = active',
        avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END), 'share', count(*)
        FROM comp WHERE in_primary_population AND tender_status = 'active'
 UNION ALL SELECT 'COM-10', 'Competition', 'Median tenderers, primary, National Competitive Bidding', '[Median Tenderers (primary)]', 'method = National Competitive Bidding',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)::numeric, 'count', count(*)
        FROM comp WHERE in_primary_population AND procurement_method_details = 'National Competitive Bidding'
 UNION ALL SELECT 'COM-B' || b, 'Competition', 'Participation band ' || b || ' (' ||
        (ARRAY['1 tenderer','2 tenderers','3-5 tenderers','6-10 tenderers','11-20 tenderers','21-50 tenderers','51-100 tenderers','101-1,000 (sensitivity only)'])[b] || '): tenders',
        '[Tenders (n)] by [Participation Band]', CASE WHEN b = 8 THEN 'population = sensitivity only' ELSE 'population = primary' END,
        count(*)::numeric, 'count', (SELECT count(*) FROM comp)
        FROM comp_b WHERE (b < 8 AND prim) OR (b = 8 AND NOT prim) GROUP BY b

 -- ======== BVA: budget-to-award ========
 UNION ALL SELECT 'BVA-01', 'Budget vs award', 'Comparable OCIDs', '[Comparable OCIDs]', 'none',
        count(*)::numeric, 'count', count(*) FROM bva
 UNION ALL SELECT 'BVA-02', 'Budget vs award', 'Total planned budget of comparable OCIDs, NGN', '[Budget of Comparable OCIDs (NGN)]', 'none',
        sum(budget_amount), 'NGN', count(*) FROM bva
 UNION ALL SELECT 'BVA-03', 'Budget vs award', 'Total award value of comparable OCIDs, NGN', '[Award of Comparable OCIDs (NGN)]', 'none',
        sum(award_value_amount), 'NGN', count(*) FROM bva
 UNION ALL SELECT 'BVA-04', 'Budget vs award', 'Net difference (award minus budget), NGN', '[Net Variance (NGN)]', 'none',
        sum(variance_amount), 'NGN', count(*) FROM bva
 UNION ALL SELECT 'BVA-05', 'Budget vs award', 'Aggregate award-to-budget ratio', '[Aggregate Award-to-Budget Ratio]', 'none',
        sum(award_value_amount) / sum(budget_amount), 'ratio', count(*) FROM bva
 UNION ALL SELECT 'BVA-06', 'Budget vs award', 'Median award-to-budget ratio', '[Median Award-to-Budget Ratio]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio)::numeric, 'ratio', count(*) FROM bva
 UNION ALL SELECT 'BVA-07', 'Budget vs award', 'Share of OCIDs within 10% of budget (ratio 0.9 to 1.1)', '[Share Within 10% of Budget]', 'none',
        avg(CASE WHEN award_to_budget_ratio BETWEEN 0.9 AND 1.1 THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM bva
 UNION ALL SELECT 'BVA-08', 'Budget vs award', 'Aggregate ratio, National Competitive Bidding', '[Aggregate Award-to-Budget Ratio]', 'method = National Competitive Bidding',
        sum(award_value_amount) / sum(budget_amount), 'ratio', count(*) FROM bva WHERE procurement_method_details = 'National Competitive Bidding'
 UNION ALL SELECT 'BVA-09', 'Budget vs award', 'Median ratio, Emergency', '[Median Award-to-Budget Ratio]', 'method = Emergency',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_to_budget_ratio)::numeric, 'ratio', count(*) FROM bva WHERE procurement_method_details = 'Emergency'
 UNION ALL SELECT 'BVA-10', 'Budget vs award', 'Net difference, Federal Ministry of Works & Housing HQ, NGN', '[Net Variance (NGN)]', 'buyer = NG-BPP-BPP-NOC-231001001',
        sum(variance_amount), 'NGN', count(*) FROM bva WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'BVA-11', 'Budget vs award', 'OCIDs with a budget under NGN 100,000 (placeholder-like, kept)', '[OCIDs With Budget Under 100k]', 'none',
        count(*) FILTER (WHERE budget_amount < 100000)::numeric, 'count', count(*) FROM bva
 UNION ALL SELECT 'BVA-B' || b, 'Budget vs award', 'Ratio band ' || b || ' (' ||
        (ARRAY['below 0.5','0.5 to under 0.9','0.9 to 1.1','over 1.1 to 1.5','over 1.5 to 10','over 10'])[b] || '): OCIDs',
        '[Comparable OCIDs] by [Ratio Band]', 'none',
        count(*)::numeric, 'count', (SELECT count(*) FROM bva) FROM bva_b GROUP BY b

 -- ======== TIM: timing (M-E01, M-E02, signature lag) ========
 UNION ALL SELECT 'TIM-01', 'Timing', 'Eligible tenders, tender open duration (M-E01)', '[Tender Duration n]', 'none',
        count(*)::numeric, 'count', count(*) FROM td
 UNION ALL SELECT 'TIM-02', 'Timing', 'Eligible OCIDs, award lag (M-E02)', '[Award Lag n]', 'none',
        count(*)::numeric, 'count', count(*) FROM al
 UNION ALL SELECT 'TIM-03', 'Timing', 'Eligible contracts, signature lag', '[Signature Lag n]', 'none',
        count(*)::numeric, 'count', count(*) FROM sl
 UNION ALL SELECT 'TIM-04', 'Timing', 'Median tender open duration, days', '[Median Tender Duration (days)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days)::numeric, 'days', count(*) FROM td
 UNION ALL SELECT 'TIM-05', 'Timing', 'Median award lag, days', '[Median Award Lag (days)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)::numeric, 'days', count(*) FROM al
 UNION ALL SELECT 'TIM-06', 'Timing', 'Median signature lag, days', '[Median Signature Lag (days)]', 'none',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY signature_lag_days)::numeric, 'days', count(*) FROM sl
 UNION ALL SELECT 'TIM-07', 'Timing', '90th percentile tender open duration, days', '[P90 Tender Duration (days)]', 'none',
        percentile_cont(0.9) WITHIN GROUP (ORDER BY tender_duration_days)::numeric, 'days', count(*) FROM td
 UNION ALL SELECT 'TIM-08', 'Timing', '90th percentile award lag, days', '[P90 Award Lag (days)]', 'none',
        percentile_cont(0.9) WITHIN GROUP (ORDER BY award_lag_days)::numeric, 'days', count(*) FROM al
 UNION ALL SELECT 'TIM-09', 'Timing', '90th percentile signature lag, days', '[P90 Signature Lag (days)]', 'none',
        percentile_cont(0.9) WITHIN GROUP (ORDER BY signature_lag_days)::numeric, 'days', count(*) FROM sl
 UNION ALL SELECT 'TIM-10', 'Timing', 'Coverage of M-E01 (eligible share of candidate tenders)', '[Coverage M-E01]', 'none',
        eligible_count::numeric / candidate_count, 'share', eligible_count FROM reg WHERE metric_id = 'M-E01'
 UNION ALL SELECT 'TIM-11', 'Timing', 'Coverage of M-E02 (eligible share of candidate OCIDs)', '[Coverage M-E02]', 'none',
        eligible_count::numeric / candidate_count, 'share', eligible_count FROM reg WHERE metric_id = 'M-E02'
 UNION ALL SELECT 'TIM-12', 'Timing', 'Coverage of signature lag (eligible share of candidate contracts)', '[Coverage Signature Lag]', 'none',
        eligible_count::numeric / candidate_count, 'share', eligible_count FROM reg WHERE metric_id = 'P5-SIG'
 UNION ALL SELECT 'TIM-13', 'Timing', 'Share of award lags over one year', '[Award Lag Over 1 Year Share]', 'none',
        avg(CASE WHEN award_lag_days > 365 THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM al
 UNION ALL SELECT 'TIM-14', 'Timing', 'Median award lag, Emergency, days', '[Median Award Lag (days)]', 'method = Emergency',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)::numeric, 'days', count(*) FROM al WHERE procurement_method_details = 'Emergency'
 UNION ALL SELECT 'TIM-15', 'Timing', 'Median award lag, National Competitive Bidding, days', '[Median Award Lag (days)]', 'method = National Competitive Bidding',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY award_lag_days)::numeric, 'days', count(*) FROM al WHERE procurement_method_details = 'National Competitive Bidding'
 UNION ALL SELECT 'TIM-16', 'Timing', 'Median tender open duration, tender start year 2020, days', '[Median Tender Duration (days)]', 'Tender Start Year = 2020',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days)::numeric, 'days', count(*) FROM td WHERE extract(year FROM tender_start_date) = 2020
 UNION ALL SELECT 'TIM-17', 'Timing', 'Median tender open duration, tender start year 2021, days', '[Median Tender Duration (days)]', 'Tender Start Year = 2021',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY tender_duration_days)::numeric, 'days', count(*) FROM td WHERE extract(year FROM tender_start_date) = 2021
 UNION ALL SELECT 'TIM-D' || mk || '-' || b, 'Timing',
        (ARRAY['Tender open duration','Award lag','Signature lag'])[mk] || ', band ' || b || ' (' ||
        (ARRAY['up to 7 days','8-30 days','31-90 days','91-180 days','181-365 days','over 1 year'])[b] || '): processes',
        '[Tender Duration n] / [Award Lag n] / [Signature Lag n] by [Duration Band]', 'none',
        count(*)::numeric, 'count', (SELECT count(*) FROM dur_b d2 WHERE d2.mk = dur_b.mk) FROM dur_b GROUP BY mk, b

 -- ======== ENT: entity benchmarking ========
 UNION ALL SELECT 'ENT-01', 'Entity benchmark', 'Procuring entities (complete buyer IDs)', '[Entities (n)]', 'none',
        count(*)::numeric, 'count', count(*) FROM eb
 UNION ALL SELECT 'ENT-02', 'Entity benchmark', 'Processes across entities', '[Entity Processes]', 'none',
        sum(process_count)::numeric, 'count', count(*) FROM eb
 UNION ALL SELECT 'ENT-03', 'Entity benchmark', 'Planned budget across entities, NGN', '[Entity Planned Budget (NGN)]', 'none',
        sum(planned_budget_total), 'NGN', count(*) FROM eb
 UNION ALL SELECT 'ENT-04', 'Entity benchmark', 'Awarded value across entities, NGN', '[Entity Award Value (NGN)]', 'none',
        sum(award_value_total), 'NGN', count(*) FROM eb
 UNION ALL SELECT 'ENT-05', 'Entity benchmark', 'Largest entity share of awarded value', '[Top N Entity Share] with N = 1', 'none',
        sum(v) FILTER (WHERE rn <= 1) / max(tot), 'share', (SELECT count(*) FROM eb) FROM eb_rk
 UNION ALL SELECT 'ENT-06', 'Entity benchmark', 'Top-10 entities share of awarded value', '[Top N Entity Share] with N = 10', 'none',
        sum(v) FILTER (WHERE rn <= 10) / max(tot), 'share', (SELECT count(*) FROM eb) FROM eb_rk
 UNION ALL SELECT 'ENT-07', 'Entity benchmark', 'Top-100 entities share of awarded value', '[Top N Entity Share] with N = 100', 'none',
        sum(v) FILTER (WHERE rn <= 100) / max(tot), 'share', (SELECT count(*) FROM eb) FROM eb_rk
 UNION ALL SELECT 'ENT-08', 'Entity benchmark', 'Median of entity single-bidder rates (entities with at least 30 primary tenders)', '[Median Entity Single-Bidder Rate]', 'Min competition n = 30',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY single_bidder_rate)::numeric, 'share', count(*) FROM eb WHERE competition_n >= 30
 UNION ALL SELECT 'ENT-09', 'Entity benchmark', 'Median of entity top-supplier shares (entities with at least 10 awards)', '[Median Entity Top-Supplier Share]', 'Min award n = 10',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY top_supplier_value_share)::numeric, 'share', count(*) FROM eb WHERE award_n >= 10
 UNION ALL SELECT 'ENT-10', 'Entity benchmark', 'Median of entity implementation coverage (entities with at least 20 contracts)', '[Median Entity Implementation Coverage]', 'Min contract n = 20',
        percentile_cont(0.5) WITHIN GROUP (ORDER BY implementation_coverage_rate)::numeric, 'share', count(*) FROM eb WHERE contract_n >= 20
 UNION ALL SELECT 'ENT-11', 'Entity benchmark', 'Works & Housing HQ: single-bidder rate', '[Entity Single-Bidder Rate]', 'buyer = NG-BPP-BPP-NOC-231001001',
        single_bidder_rate, 'share', competition_n FROM eb WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'ENT-12', 'Entity benchmark', 'Works & Housing HQ: top-supplier share', '[Entity Top-Supplier Share]', 'buyer = NG-BPP-BPP-NOC-231001001',
        top_supplier_value_share, 'share', award_n FROM eb WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'ENT-13', 'Entity benchmark', 'Works & Housing HQ: implementation coverage', '[Entity Implementation Coverage]', 'buyer = NG-BPP-BPP-NOC-231001001',
        implementation_coverage_rate, 'share', contract_n FROM eb WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'ENT-14', 'Entity benchmark', 'Works & Housing HQ: tender reach rate', '[Entity Tender Reach Rate]', 'buyer = NG-BPP-BPP-NOC-231001001',
        tender_reach_rate, 'share', process_count FROM eb WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'ENT-15', 'Entity benchmark', 'Works & Housing HQ: median award value, NGN', '[Entity Median Award Value (NGN)]', 'buyer = NG-BPP-BPP-NOC-231001001',
        median_award_value, 'NGN', award_n FROM eb WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'

 -- ======== IMP: implementation coverage and lifecycle ========
 UNION ALL SELECT 'IMP-01', 'Implementation & lifecycle', 'Contracts in scope (M-I01)', '[Contracts (n)]', 'none',
        count(*)::numeric, 'count', count(*) FROM ct
 UNION ALL SELECT 'IMP-02', 'Implementation & lifecycle', 'Contracts with implementation data', '[Contracts With Implementation Data]', 'none',
        count(*) FILTER (WHERE has_implementation)::numeric, 'count', count(*) FROM ct
 UNION ALL SELECT 'IMP-03', 'Implementation & lifecycle', 'Implementation reporting coverage rate (M-I01)', '[Implementation Coverage Rate]', 'none',
        avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM ct
 UNION ALL SELECT 'IMP-04', 'Implementation & lifecycle', 'Coverage rate, contract status pending', '[Implementation Coverage Rate]', 'contract_status = pending',
        avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM ct WHERE contract_status = 'pending'
 UNION ALL SELECT 'IMP-05', 'Implementation & lifecycle', 'Coverage rate, Works & Housing HQ', '[Implementation Coverage Rate]', 'buyer = NG-BPP-BPP-NOC-231001001',
        avg(CASE WHEN has_implementation THEN 1.0 ELSE 0.0 END), 'share', count(*) FROM ct WHERE buyer_id = 'NG-BPP-BPP-NOC-231001001'
 UNION ALL SELECT 'IMP-T' || tt.t, 'Implementation & lifecycle', 'Implementation data type ' || tt.t || ' (' ||
        (ARRAY['transactions and milestones','milestones only','transactions only','no implementation data'])[tt.t] || '): contracts',
        '[Contracts (n)] by [Implementation Data Type]', 'none',
        count(i.t)::numeric, 'count', (SELECT count(*) FROM ct)
        FROM generate_series(1, 4) AS tt(t) LEFT JOIN impl_t i USING (t) GROUP BY tt.t
 UNION ALL SELECT 'IMP-S' || k, 'Implementation & lifecycle', 'Lifecycle: OCIDs reaching stage ' || k || ' (' ||
        (ARRAY['planning','tender','award','contract','implementation'])[k] || ') or beyond',
        '[OCIDs Reaching Stage]', 'Stage = ' || k, reached::numeric, 'count', (SELECT count(*) FROM lc) FROM stage
 UNION ALL SELECT 'IMP-C' || s.k, 'Implementation & lifecycle', 'Lifecycle: conversion from stage ' || (s.k - 1) || ' to stage ' || s.k,
        '[Stage Conversion Rate]', 'Stage = ' || s.k, s.reached::numeric / p.reached, 'share', p.reached
        FROM stage s JOIN stage p ON p.k = s.k - 1

 -- ======== DQ: data-quality and coverage page ========
 UNION ALL SELECT 'DQ-C-' || rtrim(regexp_replace(metric_id, '[^A-Za-z0-9]+', '-', 'g'), '-'), 'Data quality & coverage', 'Candidate population: ' || metric_id, 'MetricPopulation[candidate_count]', 'none',
        candidate_count::numeric, 'count', candidate_count FROM reg
 UNION ALL SELECT 'DQ-E-' || rtrim(regexp_replace(metric_id, '[^A-Za-z0-9]+', '-', 'g'), '-'), 'Data quality & coverage', 'Eligible population: ' || metric_id, 'MetricPopulation[eligible_count]', 'none',
        eligible_count::numeric, 'count', eligible_count FROM reg
 UNION ALL SELECT 'DQ-P-' || rtrim(regexp_replace(metric_id, '[^A-Za-z0-9]+', '-', 'g'), '-'), 'Data quality & coverage', 'Eligible share of candidates: ' || metric_id, '[Eligible Share]', 'none',
        eligible_count::numeric / candidate_count, 'share', eligible_count FROM reg
 UNION ALL SELECT 'DQ-X1', 'Data quality & coverage', 'M-P01 extreme budgets (DQ-06): lines excluded', 'DQImpact[records_with_issue]', 'metric = M-P01, issue = DQ-06',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-P01' AND dq_ref = 'DQ-06'
 UNION ALL SELECT 'DQ-X2', 'Data quality & coverage', 'M-P01 extreme budgets (DQ-06): value excluded, NGN', 'DQImpact[affected_value_ngn]', 'metric = M-P01, issue = DQ-06',
        affected_value_ngn, 'NGN', candidate_records FROM dq WHERE metric_id = 'M-P01' AND dq_ref = 'DQ-06'
 UNION ALL SELECT 'DQ-X3', 'Data quality & coverage', 'M-V01 extreme award (DQ-07): awards excluded', 'DQImpact[records_with_issue]', 'metric = M-V01, issue = DQ-07',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-V01' AND dq_ref = 'DQ-07'
 UNION ALL SELECT 'DQ-X4', 'Data quality & coverage', 'M-V01 portal test entity (DQ-20): awards removed before the candidate population', 'DQImpact[records_with_issue]', 'metric = M-V01, issue = DQ-20',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-V01' AND dq_ref = 'DQ-20'
 UNION ALL SELECT 'DQ-X5', 'Data quality & coverage', 'M-E02 chronology conflicts (award before tender start): excluded', 'DQImpact[records_with_issue]', 'metric = M-E02, issue = DATE-ORDER',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-E02' AND dq_ref = 'DATE-ORDER'
 UNION ALL SELECT 'DQ-X6', 'Data quality & coverage', 'M-E01 records excluded for any reason (candidate minus eligible)', 'DQImpact[records_with_issue]', 'metric = M-E01, issue = ALL',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-E01' AND dq_ref = 'ALL'
 UNION ALL SELECT 'DQ-X7', 'Data quality & coverage', 'M-S01 awards with several name variants (DQ-13, disclosed, kept)', 'DQImpact[records_with_issue]', 'metric = M-S01, issue = DQ-13',
        records_with_issue::numeric, 'count', candidate_records FROM dq WHERE metric_id = 'M-S01' AND dq_ref = 'DQ-13'
)
SELECT figure_id, page, figure, dax_measure, slice, expected_value, unit, eligible_n
FROM f
ORDER BY array_position(ARRAY['Executive overview', 'Supplier concentration', 'Competition', 'Budget vs award', 'Timing',
                              'Entity benchmark', 'Implementation & lifecycle', 'Data quality & coverage'], page),
         figure_id;
