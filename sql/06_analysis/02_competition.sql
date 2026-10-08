-- ============================================================
-- NOCOPO — Phase 8, business question 2: competition
-- ============================================================
-- Question: How competitive are procurement processes based on available
--           tenderer information, and where are unusually low or high levels
--           of competition observed?  (Scope s.6, Pillar 2)
-- Metrics:  M-C01 median number of tenderers; M-C02 single-bidder rate
-- Source:   analytics.vw_competition_eligible (one tender per OCID)
-- Run:      psql -h localhost -p 5433 -U postgres -d nocopo_db -f sql/06_analysis/02_competition.sql
--
-- ELIGIBLE POPULATION
--   PRIMARY    tender status not null and 1-100 tenderers (flag NORMAL; DQ-03).
--              All headline M-C01 / M-C02 figures use this population.
--   SENSITIVITY adds 101-1,000 tenderers (flag ELEVATED; DQ-04, 14 tenders).
--              Tenders above 1,000 (ANOMALOUS; DQ-05) are excluded from both.
--   All non-null tender statuses are kept (Kene I-3) and used for
--   segmentation in RS5, not as a filter.
--
-- LIMITATIONS TO STATE WITH EVERY RESULT
--   1. number_of_tenderers is 0% null and always >= 1, so a missing count is
--      never read as zero participation. The field's meaning (bids received vs.
--      expressions of interest) is unconfirmed in the source.
--   2. Competition here is the number of tenderers, not the quality of
--      competition. A single bidder is an observed pattern, not evidence of
--      impropriety: some methods (Sole Source, Direct Procurement) are single
--      supplier by design, so compare like with like (RS4).
--   3. Entity comparisons use entities with at least min_tenders primary
--      tenders (parameter in RS6); small entities are too noisy to rank.
--   4. Percentile and quartile positions rank entities against each other. They
--      are relative positions, not thresholds of acceptable competition.
-- ============================================================

-- [RS1] Eligible populations and headline metrics
SELECT 'primary (NORMAL, 1-100)'                                           AS population,
       count(*) FILTER (WHERE in_primary_population)                       AS eligible_tenders,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
           FILTER (WHERE in_primary_population)                            AS median_tenderers_m_c01,
       round(avg(CASE WHEN is_single_bidder THEN 100.0 ELSE 0.0 END)
           FILTER (WHERE in_primary_population), 2)                        AS single_bidder_rate_pct_m_c02,
       round(avg(number_of_tenderers) FILTER (WHERE in_primary_population), 2) AS mean_tenderers,
       max(number_of_tenderers) FILTER (WHERE in_primary_population)       AS max_tenderers
FROM analytics.vw_competition_eligible
UNION ALL
SELECT 'sensitivity (NORMAL + ELEVATED)',
       count(*),
       percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers),
       round(avg(CASE WHEN is_single_bidder THEN 100.0 ELSE 0.0 END), 2),
       round(avg(number_of_tenderers), 2),
       max(number_of_tenderers)
FROM analytics.vw_competition_eligible
ORDER BY population;

-- [RS1b] Register entry (analytics.vw_metric_population; about 40 s because the register evaluates every view)
SELECT metric_id, candidate_population, candidate_count, eligible_count, eligible_pct
FROM analytics.vw_metric_population
WHERE metric_id IN ('M-C01 / M-C02', 'M-C01 (sensitivity)')
ORDER BY metric_id;

-- [RS2] Participation bands (CASE classification) with cumulative share
WITH banded AS (
    SELECT CASE
               WHEN number_of_tenderers = 1    THEN '1  single bidder'
               WHEN number_of_tenderers = 2    THEN '2  two tenderers'
               WHEN number_of_tenderers <= 5   THEN '3  3-5 tenderers'
               WHEN number_of_tenderers <= 10  THEN '4  6-10 tenderers'
               WHEN number_of_tenderers <= 20  THEN '5  11-20 tenderers'
               WHEN number_of_tenderers <= 50  THEN '6  21-50 tenderers'
               WHEN number_of_tenderers <= 100 THEN '7  51-100 tenderers'
               ELSE                                 '8  101-1,000 (ELEVATED, sensitivity only)'
           END AS participation_band,
           in_primary_population
    FROM analytics.vw_competition_eligible
)
SELECT participation_band,
       count(*) FILTER (WHERE in_primary_population)                                  AS primary_tenders,
       round(100.0 * count(*) FILTER (WHERE in_primary_population)
             / sum(count(*) FILTER (WHERE in_primary_population)) OVER (), 2)         AS pct_of_primary,
       round(100.0 * sum(count(*) FILTER (WHERE in_primary_population))
             OVER (ORDER BY participation_band)
             / sum(count(*) FILTER (WHERE in_primary_population)) OVER (), 2)         AS cumulative_pct_of_primary,
       count(*) FILTER (WHERE NOT in_primary_population)                              AS sensitivity_only_tenders
FROM banded
GROUP BY participation_band
ORDER BY participation_band;

-- [RS3] Percentiles of tenderers (primary)
SELECT count(*)                                                   AS eligible_tenders,
       min(number_of_tenderers)                                   AS min_tenderers,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY number_of_tenderers) AS p25,
       percentile_cont(0.50) WITHIN GROUP (ORDER BY number_of_tenderers) AS median,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY number_of_tenderers) AS p75,
       percentile_cont(0.90) WITHIN GROUP (ORDER BY number_of_tenderers) AS p90,
       percentile_cont(0.99) WITHIN GROUP (ORDER BY number_of_tenderers) AS p99,
       max(number_of_tenderers)                                   AS max_tenderers
FROM analytics.vw_competition_eligible
WHERE in_primary_population;

-- [RS4] Competition by procurement method (primary population)
WITH by_method AS (
    SELECT coalesce(procurement_method_details, '(method not stated)')      AS procurement_method,
           count(*)                                                         AS eligible_tenders,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers) AS median_tenderers,
           avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END)            AS single_bidder_rate,
           avg(CASE WHEN number_of_tenderers >= 6 THEN 1.0 ELSE 0.0 END)    AS six_plus_rate
    FROM analytics.vw_competition_eligible
    WHERE in_primary_population
    GROUP BY 1
)
SELECT procurement_method, eligible_tenders, median_tenderers,
       round(100 * single_bidder_rate, 1)                                  AS single_bidder_rate_pct,
       round(100 * six_plus_rate, 1)                                       AS six_plus_tenderers_pct,
       round(100 * single_bidder_rate
             - 100 * (sum(single_bidder_rate * eligible_tenders) OVER () / sum(eligible_tenders) OVER ()), 1)
                                                                           AS single_bidder_gap_vs_overall_pts,
       CASE WHEN eligible_tenders < 30 THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM by_method
ORDER BY eligible_tenders DESC;

-- [RS5] Competition by tender status (Kene I-3: all non-null statuses kept; segmentation only)
SELECT tender_status,
       count(*) FILTER (WHERE in_primary_population)                       AS primary_tenders,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)
           FILTER (WHERE in_primary_population)                            AS median_tenderers,
       round(100 * avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END)
           FILTER (WHERE in_primary_population), 1)                        AS single_bidder_rate_pct,
       CASE WHEN count(*) FILTER (WHERE in_primary_population) < 30 THEN 'small n: read with caution' ELSE '' END AS reliability_note
FROM analytics.vw_competition_eligible
GROUP BY tender_status
ORDER BY primary_tenders DESC;

-- [RS6] Entities at the extremes of competition (primary population, DQ-19 buyer excluded)
WITH params AS (SELECT 30 AS min_tenders),
entity AS (
    SELECT buyer_id, max(buyer_name) AS buyer_name,
           count(*)                                                          AS eligible_tenders,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY number_of_tenderers)  AS median_tenderers,
           avg(CASE WHEN is_single_bidder THEN 1.0 ELSE 0.0 END)             AS single_bidder_rate
    FROM analytics.vw_competition_eligible
    WHERE in_primary_population
      AND buyer_id_flag IS NULL
    GROUP BY buyer_id
),
scored AS (
    SELECT e.*,
           count(*)       OVER ()                                           AS entities_in_comparison,
           rank()         OVER (ORDER BY single_bidder_rate DESC, eligible_tenders DESC) AS rank_highest_single_bidder,
           rank()         OVER (ORDER BY single_bidder_rate ASC,  eligible_tenders DESC) AS rank_lowest_single_bidder,
           ntile(4)       OVER (ORDER BY single_bidder_rate)                AS single_bidder_quartile   -- 4 = highest
    FROM entity e, params p
    WHERE e.eligible_tenders >= p.min_tenders
)
SELECT 'highest single-bidder rate'                      AS ranking,
       rank_highest_single_bidder                        AS rank_in_group,
       buyer_id, buyer_name, eligible_tenders, median_tenderers,
       round(100 * single_bidder_rate, 1)                AS single_bidder_rate_pct,
       single_bidder_quartile, entities_in_comparison
FROM scored
WHERE rank_highest_single_bidder <= 10
UNION ALL
SELECT 'lowest single-bidder rate',
       rank_lowest_single_bidder,
       buyer_id, buyer_name, eligible_tenders, median_tenderers,
       round(100 * single_bidder_rate, 1),
       single_bidder_quartile, entities_in_comparison
FROM scored
WHERE rank_lowest_single_bidder <= 10
ORDER BY ranking DESC, rank_in_group;
